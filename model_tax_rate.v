module peony

import arrays
import einar_hjortdal.firebird

const tax_additive = 'additive'
const tax_substitutive = 'substitutive'
const tax_compounding = 'compounding'

// TODO replace join tables with region_id product_id product_type_id columns
// make the app delete tax_rate when any product/region/product_type is deleted
// app ensures no tax_rate is created with more than one of these 3 columns

struct TaxRate {
	id         string
	id_bin     []u8
	created_at firebird.DateTime
	updated_at firebird.DateTime
	deleted_at firebird.NullDateTime
	rate       f32
	code       firebird.NullString
	name       string
	tax_type   string
}

fn model_tax_rate_retrieve(mut tx firebird.Transaction, tax_rate_ids_bin [][]u8) ![]TaxRate {
	data := tx.execute('SELECT
		id,
		created_at,
		updated_at,
		deleted_at,
		rate,
		code,
		name,
		type
		FROM tax_rate
		WHERE id IN (${get_placeholders(tax_rate_ids_bin)})',
		...tax_rate_ids_bin)!

	rows := data.rows()

	mut tax_rates := []TaxRate{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()
		id_bin, _ := v[0].get_array_u8()!
		created_at, _ := v[1].get_date_time()!
		updated_at, _ := v[2].get_date_time()!
		deleted_at := v[3].get_null_date_time()!
		rate, _ := v[4].get_f32()!
		code := v[5].get_null_string()!
		name, _ := v[6].get_string()!
		tax_type, _ := v[7].get_string()!

		id := id_bin_to_string(id_bin)!

		tax_rates[i] = TaxRate{
			id:         id
			id_bin:     id_bin
			created_at: created_at
			updated_at: updated_at
			deleted_at: deleted_at
			rate:       rate
			code:       code
			name:       name
			tax_type:   tax_type
		}
	}
	return tax_rates
}

fn model_region_tax_rate_retrieve(mut tx firebird.Transaction, region_ids_bin [][]u8) !([][]u8, map[string][][]u8) {
	data := tx.execute('SELECT region_id, rate_id FROM region_tax_rate
	WHERE region_id IN (${get_placeholders(region_ids_bin)})',
		...region_ids_bin)!

	rows := data.rows()

	mut rates := [][]u8{len: rows.len}
	mut mapping := map[string][][]u8{}
	for i := 0; i < rows.len; i++ {
		values := rows[i].values()
		region_id_bin, _ := values[0].get_array_u8()!
		rate_id_bin, _ := values[1].get_array_u8()!
		region_id := id_bin_to_string(region_id_bin)!
		mapping[region_id] = arrays.concat(mapping[region_id], rate_id_bin)
		rates[i] = rate_id_bin
	}

	return rates, mapping
}
