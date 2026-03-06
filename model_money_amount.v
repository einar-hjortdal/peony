module peony

import einar_hjortdal.firebird

const default_money_amount = i32(0)

struct VariantMoneyAmount {
	id             string
	id_bin         []u8
	variant_id     string
	variant_id_bin []u8 // from product_variant_money_amount
	amount         i32
	is_original    bool
	region_id      string
	region_id_bin  []u8
	currency_code  string // from region
	includes_tax   bool   // from region
}

fn model_variant_money_amount_retrieve(mut tx firebird.Transaction, variant_ids_bin [][]u8) ![]VariantMoneyAmount {
	data := tx.execute('SELECT
		ma.id,
		ma.amount,
		ma.is_original,
		ma.region_id,
		r.currency_code,
		r.includes_tax,
		pvma.variant_id
		FROM money_amount ma
		LEFT JOIN region r
			ON ma.region_id = r.id
		LEFT JOIN product_variant_money_amount pvma
			ON ma.id = pvma.money_amount_id
		WHERE variant_id IN (${get_placeholders(variant_ids_bin)})',
		...workaround_24757(variant_ids_bin))!

	rows := data.rows()

	mut variant_money_amounts := []VariantMoneyAmount{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()

		id_bin, _ := v[0].get_array_u8()!
		amount, _ := v[1].get_i32()!
		is_original, _ := v[2].get_bool()!
		region_id_bin, _ := v[3].get_array_u8()!
		currency_code, _ := v[4].get_string()!
		includes_tax, _ := v[5].get_bool()!
		variant_id_bin, _ := v[6].get_array_u8()!

		id := id_bin_to_string(id_bin)!
		region_id := id_bin_to_string(region_id_bin)!
		variant_id := id_bin_to_string(variant_id_bin)!

		variant_money_amounts[i] = VariantMoneyAmount{
			id:             id
			id_bin:         id_bin
			amount:         amount
			region_id:      region_id
			region_id_bin:  region_id_bin
			is_original:    is_original
			currency_code:  currency_code
			includes_tax:   includes_tax
			variant_id:     variant_id
			variant_id_bin: variant_id_bin
		}
	}

	return variant_money_amounts
}

struct VariantMoneyAmountUpdateParams {
	variant_id          string
	variant_id_bin      []u8
	region_id           string
	region_id_bin       []u8
	money_amount_id     string
	money_amount_id_bin []u8
	amount              i32
	is_original         bool
}

fn model_variant_money_amount_update(mut tx firebird.Transaction, p []VariantMoneyAmountUpdateParams) ! {
	// deduplicate variant ids
	mut variant_ids_map := map[string][]u8{}
	for i := 0; i < p.len; i++ {
		variant_id := p[i].variant_id
		variant_id_bin := p[i].variant_id_bin
		variant_ids_map[variant_id] = variant_id_bin
	}

	mut variant_ids_bin := [][]u8{len: variant_ids_map.len}
	mut idx := 0
	for _, id_bin in variant_ids_map {
		variant_ids_bin[idx] = id_bin
		idx++
	}

	// delete all related money amount first
	tx.execute('DELETE FROM money_amount
		WHERE id IN (
			SELECT money_amount_id
			FROM product_variant_money_amount
			WHERE variant_id IN (${get_placeholders(variant_ids_bin)})
		)
		AND price_list_id IS NULL',
		...workaround_24757(variant_ids_bin))!

	mut n_params := 4
	mut src := []string{len: p.len}
	mut params := []firebird.Value{len: p.len * n_params, init: firebird.Null{}}
	for i := 0; i < p.len; i++ {
		src[i] = 'SELECT
			CAST(? AS BINARY(16)) AS id,
			CAST(? AS BINARY(16)) AS region_id,
			CAST(? AS BOOLEAN) AS is_original,
			CAST(? AS INTEGER) AS amount
			FROM RDB\$DATABASE'

		params[i * n_params] = p[i].money_amount_id_bin
		params[i * n_params + 1] = p[i].region_id_bin
		params[i * n_params + 2] = p[i].is_original
		params[i * n_params + 3] = p[i].amount
	}

	tx.execute('INSERT INTO money_amount (id, region_id, is_original, amount) ${get_merge_source(src)}',
		...params)!

	n_params = 2
	params = []firebird.Value{len: p.len * n_params, init: firebird.Null{}}
	for i := 0; i < p.len; i++ {
		src[i] = 'SELECT
			CAST(? AS BINARY(16)) AS variant_id,
			CAST(? AS BINARY(16)) AS money_amount_id
			FROM RDB\$DATABASE'

		params[i * n_params] = p[i].variant_id_bin
		params[i * n_params + 1] = p[i].money_amount_id_bin
	}

	tx.execute('INSERT INTO product_variant_money_amount (variant_id, money_amount_id)
		${get_merge_source(src)}',
		...params)!
}
