module peony

import log
import einar_hjortdal.firebird

const default_moeny_amount = i32(0)

struct MoneyAmount {
	id                string
	id_bin            []u8
	amount            i32
	is_original       bool
	min_quantity      firebird.NullI32
	max_quantity      firebird.NullI32
	price_list_id_bin firebird.NullArrayU8
	region_id         string
	region_id_bin     []u8
	currency_code     string               // from region
	includes_tax      bool                 // from region
	variant_id_bin    firebird.NullArrayU8 // from product_variant_money_amount
}

struct VariantMoneyAmountCreateDefaultParams {
	variant_id_bin       []u8
	region_ids_bin       [][]u8
	money_amount_ids_bin [][]u8
}

fn model_product_variant_money_amount_create_default(mut tx firebird.Transaction, p VariantMoneyAmountCreateDefaultParams) ! {
	log.debug('Creating default money_amount entries')
	mut src := []string{len: p.region_ids_bin.len}
	mut params := []firebird.Value{len: p.region_ids_bin.len * 3, init: firebird.Null{}}
	for i := 0; i < p.region_ids_bin.len; i++ {
		region_id_bin := p.region_ids_bin[i]
		money_amount_id_bin := p.money_amount_ids_bin[i]
		src[i] = 'SELECT
			CAST(? AS BINARY(16)) AS id,
			CAST(? AS BINARY(16)) AS region_id,
			CAST(? AS INTEGER) AS amount
			FROM RDB\$DATABASE'
		params[i * 3] = money_amount_id_bin
		params[i * 3 + 1] = region_id_bin
		params[i * 3 + 2] = default_moeny_amount
	}

	tx.execute('INSERT INTO money_amount (id, region_id, amount) ${get_merge_source(src)}',
		...params)!

	log.debug('Creating relations in the product_variant_money_amount table')
	params = []firebird.Value{len: p.money_amount_ids_bin.len * 2, init: firebird.Null{}}
	for i := 0; i < p.money_amount_ids_bin.len; i++ {
		money_amount_id_bin := p.money_amount_ids_bin[i]
		src[i] = 'SELECT
			CAST(? AS BINARY(16)) AS variant_id,
			CAST(? AS BINARY(16)) AS money_amount_id
			FROM RDB\$DATABASE'
		params[i * 2] = p.variant_id_bin
		params[i * 2 + 1] = money_amount_id_bin
	}

	tx.execute('INSERT INTO product_variant_money_amount (variant_id, money_amount_id)
		${get_merge_source(src)}',
		...params)!
}

fn model_product_variant_money_amount_retrieve(mut tx firebird.Transaction, product_variant_ids_bin [][]u8) ![]MoneyAmount {
	data := tx.execute('SELECT
		ma.id,
		ma.amount,
		ma.min_quantity,
		ma.max_quantity,
		ma.is_original,
		ma.region_id,
		ma.price_list_id,
		r.currency_code,
		r.includes_tax,
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
		is_original, _ := v[4].get_bool()!
		region_id_bin, _ := v[5].get_array_u8()!
		price_list_id_bin := v[6].get_null_array_u8()!
		currency_code, _ := v[7].get_string()!
		includes_tax, _ := v[8].get_bool()!
		variant_id_bin := v[9].get_null_array_u8()!

		id := id_bin_to_string(id_bin)!
		region_id := id_bin_to_string(region_id_bin)!

		product_variant_money_amounts[i] = MoneyAmount{
			id:                id
			id_bin:            id_bin
			amount:            amount
			min_quantity:      min_quantity
			max_quantity:      max_quantity
			price_list_id_bin: price_list_id_bin
			region_id:         region_id
			region_id_bin:     region_id_bin
			is_original:       is_original
			currency_code:     currency_code
			includes_tax:      includes_tax
			variant_id_bin:    variant_id_bin
		}
	}

	return product_variant_money_amounts
}

// money_amount that are related to a price_list are left untouched.
fn model_product_variant_money_amount_update(mut app App, mut tx firebird.Transaction, variant_id_bin []u8, ph []VariantMoneyAmountRequestHygienised) ! {
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
	mut params := []firebird.Value{len: ph.len * 4, init: firebird.Null{}}
	for i := 0; i < ph.len; i++ {
		src[i] = 'SELECT
			CAST(? AS BINARY(16)) as id,
			CAST(? AS INTEGER) as amount,
			CAST(? AS BINARY(16)) as region_id,
			CAST(? AS BOOLEAN) as is_original
			FROM RDB\$DATABASE'
		params[i * 5] = money_amount_ids_bin[i]
		params[i * 5 + 1] = ph[i].amount
		params[i * 5 + 2] = ph[i].region_id_bin

		if is_original := ph[i].is_original {
			params[i * 5 + 3] = is_original
		} else {
			params[i * 5 + 3] = false
		}
	}

	tx.execute('INSERT INTO money_amount (id, amount, region_id, is_original)
		${get_merge_source(src)}',
		...params)!

	src = []string{len: money_amount_ids_bin.len}
	params = []firebird.Value{len: money_amount_ids_bin.len * 2, init: firebird.Null{}}
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

// fn model_price_list_money_amount_update(price_list_id []u8, []PriceListMoneyAmountRequestHygienised) ! {
// 	tx.execute('DELETE FROM money_amount
// 		WHERE price_list_id = ?
// 		AND id IN (
// 			SELECT money_amount_id
// 			FROM product_variant_money_amount
// 			WHERE variant_id IN (?, ?)
// 		)',
// 		price_list_id)!
// }
