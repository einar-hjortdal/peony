module peony

import einar_hjortdal.firebird

struct MoneyAmount {
	id                string
	id_bin            []u8
	amount            i32
	min_quantity      firebird.NullI32
	max_quantity      firebird.NullI32
	price_list_id_bin firebird.NullArrayU8
	region_id         string
	region_id_bin     []u8
	currency_code     string               // from region
	variant_id_bin    firebird.NullArrayU8 // from product_variant_money_amount
}

fn model_product_variant_money_amount_retrieve(mut tx firebird.Transaction, product_variant_ids_bin [][]u8) ![]MoneyAmount {
	data := tx.execute('SELECT
		ma.id,
		ma.amount,
		ma.min_quantity,
		ma.max_quantity,
		ma.price_list_id,
		ma.region_id,
		r.currency_code,
		pvma.variant_id
		FROM money_amount ma
		LEFT JOIN region r
			ON ma.region_id = r.id
		LEFT JOIN product_variant_money_amount pvma
			ON ma.id = pvma.money_amount_id
		WHERE variant_id IN (${get_placeholders(product_variant_ids_bin)})',
		...workaround_24757(product_variant_ids_bin))!

	rows := data.rows()

	mut product_variant_money_amounts := []MoneyAmount{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()

		id_bin, _ := v[0].get_array_u8()!
		amount, _ := v[1].get_i32()!
		min_quantity := v[2].get_null_i32()!
		max_quantity := v[3].get_null_i32()!
		price_list_id_bin := v[4].get_null_array_u8()!
		region_id_bin, _ := v[5].get_array_u8()!
		currency_code, _ := v[6].get_string()!
		variant_id_bin := v[7].get_null_array_u8()!

		id := id_bin_to_string(id_bin)!
		region_id := id_bin_to_string(region_id_bin)!

		product_variant_money_amounts[i] = MoneyAmount{
			id:                id
			id_bin:            id_bin
			currency_code:     currency_code
			amount:            amount
			min_quantity:      min_quantity
			max_quantity:      max_quantity
			price_list_id_bin: price_list_id_bin
			region_id:         region_id
			region_id_bin:     region_id_bin
			variant_id_bin:    variant_id_bin
		}
	}

	return product_variant_money_amounts
}

fn model_product_variant_money_amount_update(mut app App, mut tx firebird.Transaction, variant_id_bin []u8, ph []MoneyAmountRequestHygienised) ! {
	mut money_amount_ids_bin := [][]u8{len: ph.len}
	for i := 0; i < ph.len; i++ {
		_, id_bin := app.new_id()
		money_amount_ids_bin[i] = id_bin
	}

	tx.execute('DELETE FROM money_amount
		WHERE price_list_id IS NULL
		AND id IN (
			SELECT money_amount_id
			FROM product_variant_money_amount
			WHERE variant_id = ?
		)',
		variant_id_bin)!

	if ph.len == 0 {
		return
	}

	mut src := []string{len: ph.len}
	mut params := []firebird.Value{len: ph.len * 5, init: firebird.Value(firebird.Null{})}
	for i := 0; i < ph.len; i++ {
		src[i] = 'SELECT
			CAST(? AS BINARY(16)) as id,
			CAST(? AS INTEGER) as amount,
			CAST(? AS BINARY(16)) as region_id,
			CAST(? AS INTEGER) as min_quantity,
			CAST(? AS INTEGER) as max_quantity
			FROM RDB\$DATABASE'
		params[i * 5] = money_amount_ids_bin[i]
		params[i * 5 + 1] = ph[i].amount
		params[i * 5 + 2] = ph[i].region_id_bin

		if min_quantity := ph[i].min_quantity {
			params[i * 5 + 3] = min_quantity
		} else {
			params[i * 5 + 3] = firebird.Null{}
		}

		if max_quantity := ph[i].max_quantity {
			params[i * 5 + 4] = max_quantity
		} else {
			params[i * 5 + 4] = firebird.Null{}
		}
	}

	tx.execute('INSERT INTO money_amount (id, amount, min_quantity, max_quantity, region_id)
		${get_merge_source(src)}',
		...params)!

	src = []string{len: money_amount_ids_bin.len}
	params = []firebird.Value{len: money_amount_ids_bin.len * 2, init: firebird.Value(firebird.Null{})}
	for i := 0; i < money_amount_ids_bin.len; i++ {
		src[i] = 'SELECT
			CAST(? AS BINARY(16)) as variant_id,
			CAST(? AS BINARY(16)) as money_amount_id
			FROM RDB\$DATABASE'
		params[i * 2] = variant_id_bin
		params[i * 2 + 1] = money_amount_ids_bin[i]
	}

	tx.execute('INSERT INTO product_variant_money_amount (variant_id, money_amount_id)
		${get_merge_source(src)}',
		...params)!
}

fn model_product_variant_delete(mut tx firebird.Transaction, variant_id_bin []u8) ! {
	tx.execute('UPDATE product_variant SET deleted_at = CURRENT_TIMESTAMP WHERE id = ?',
		variant_id_bin)!
}

fn model_product_variant_product_option_value_update(mut tx firebird.Transaction)
