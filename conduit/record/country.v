module record

import arrays
import einar_hjortdal.firebird

pub struct Country {
pub:
	code      string
	region_id ?ID
}

pub struct CountryRetrieveParams {
pub:
	codes  ?[]string
	offset i32
	fetch  i32
	order  string
}

pub fn country_retrieve_conditions(p CountryRetrieveParams) (string, []firebird.Value) {
	mut conditions := []string{}
	mut params := []firebird.Value{}

	if codes := p.codes {
		conditions = arrays.concat(conditions, 'code IN (${get_placeholders(codes)})')
		params = arrays.concat(params, ...codes)
	}

	return get_where_conditions(conditions), params
}

pub fn country_retrieve_count(mut tx firebird.Transaction, p CountryRetrieveParams) !i64 {
	conditions, params := country_retrieve_conditions(p)
	data := tx.execute('SELECT COUNT(*) FROM region ${conditions}', ...params)!
	rows := data.rows()
	values := rows[0].values() // should always return one row
	count, _ := values[0].get_i64()! // should always return one column
	return count
}

pub fn country_retrieve(mut tx firebird.Transaction, p CountryRetrieveParams) ![]Country {
	conditions, mut params := country_retrieve_conditions(p)

	mut sorting := 'ORDER BY created_at ${p.order} 
		OFFSET ? ROWS
		FETCH NEXT ? ROWS ONLY'
	params = arrays.concat(params, p.offset, p.fetch)

	query := 'SELECT code, region_id FROM country ${conditions} ${sorting}'
	data := tx.execute(query, ...params)!
	rows := data.rows()

	mut countries := []Country{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()
		code, _ := v[0].get_string()!
		region_id_bin := v[1].get_null_array_u8()!

		mut region_id := ?ID(none)
		if !region_id_bin.is_null {
			region_id = id_from_bytes(region_id_bin.value)!
		}

		country := Country{
			code:      code
			region_id: region_id
		}
		countries[i] = country
	}

	return countries
}
