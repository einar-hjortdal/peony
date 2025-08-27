module peony

import einar_hjortdal.firebird

struct MoneyAmount {
	id                string
	id_bin            []u8
	currency_code     string
	amount            i32
	min_quantity      firebird.NullI32
	max_quantity      firebird.NullI32
	price_list_id_bin firebird.NullArrayU8
	region_id_bin     firebird.NullArrayU8
	variant_id_bin    firebird.NullArrayU8
}

fn model_product_variant_money_amount_retrieve(mut tx firebird.Transaction, product_variant_ids_bin [][]u8) ![]MoneyAmount {
	data := tx.execute('SELECT
		ma.id,
		ma.currency_code,
		ma.amount,
		ma.min_quantity,
		ma.max_quantity,
		ma.price_list_id,
		ma.region_id,
		pvma.variant_id
		FROM money_amount ma
		LEFT JOIN product_variant_money_amount pvma
			ON ma.id = pvma.money_amount_id
		WHERE variant_id IN (${get_placeholders(product_variant_ids_bin)})',
		...workaround_24757(product_variant_ids_bin))!

	rows := data.rows()

	mut product_variant_money_amounts := []MoneyAmount{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()
		id_bin, _ := v[0].get_array_u8()!
		currency_code, _ := v[1].get_string()!
		amount, _ := v[2].get_i32()!
		min_quantity := v[3].get_null_i32()!
		max_quantity := v[4].get_null_i32()!
		price_list_id_bin := v[5].get_null_array_u8()!
		region_id_bin := v[6].get_null_array_u8()!
		variant_id_bin := v[7].get_null_array_u8()!

		id := id_bin_to_string(id_bin)!

		product_variant_money_amounts[i] = MoneyAmount{
			id:                id
			id_bin:            id_bin
			currency_code:     currency_code
			amount:            amount
			min_quantity:      min_quantity
			max_quantity:      max_quantity
			price_list_id_bin: price_list_id_bin
			region_id_bin:     region_id_bin
			variant_id_bin:    variant_id_bin
		}
	}

	return product_variant_money_amounts
}
