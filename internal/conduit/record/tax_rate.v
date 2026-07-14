module record

import einar_hjortdal.firebird
import internal.common

pub const tax_additive = 'additive'
pub const tax_substitutive = 'substitutive'
pub const tax_compounding = 'compounding'

// TODO replace join tables with region_id product_id product_type_id columns
// make the app delete tax_rate when any product/region/product_type is deleted
// app ensures no tax_rate is created with more than one of these 3 columns

pub struct TaxRate {
pub:
	id         common.ID
	created_at firebird.DateTime
	updated_at firebird.DateTime
	deleted_at ?firebird.DateTime
	rate       f32
	code       ?string
	name       string
	tax_type   string
}

pub fn (r TaxRate) id() common.ID {
	return r.id
}

pub fn tax_rate_retrieve(mut tx firebird.ClientTransaction, tax_rate_ids []common.ID) ![]TaxRate {
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

		id := common.id_from_bytes(id_bin)!

		tax_rates[i] = TaxRate{
			id:         id
			created_at: created_at
			updated_at: updated_at
			deleted_at: deleted_at.none_value()
			rate:       rate
			code:       code.none_value()
			name:       name
			tax_type:   tax_type
		}
	}
	return tax_rates
}
