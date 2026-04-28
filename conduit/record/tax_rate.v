module record

import arrays
import einar_hjortdal.firebird

pub const tax_additive = 'additive'
pub const tax_substitutive = 'substitutive'
pub const tax_compounding = 'compounding'

// TODO replace join tables with region_id product_id product_type_id columns
// make the app delete tax_rate when any product/region/product_type is deleted
// app ensures no tax_rate is created with more than one of these 3 columns

pub struct TaxRate {
pub:
	id         ID
	created_at firebird.DateTime
	updated_at firebird.DateTime
	deleted_at firebird.NullDateTime
	rate       f32
	code       firebird.NullString
	name       string
	tax_type   string
}

pub fn (r TaxRate) id() ID {
	return r.id
}

pub fn tax_rate_retrieve(mut tx firebird.Transaction, tax_rate_ids []ID) ![]TaxRate {
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
		WHERE id IN (${get_placeholders(tax_rate_ids)})',
		...tax_rate_ids)!

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

		id := id_from_bytes(id_bin)!

		tax_rates[i] = TaxRate{
			id:         id
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

