module peony

import arrays
import einar_hjortdal.firebird

struct Country {
	code          string
	region_id_bin firebird.NullArrayU8
}

fn model_country_list(mut tx firebird.Transaction, p ListCountriesParams) !([]Country, i64) {
	mut query := 'SELECT code, region_id, COUNT(*) OVER() FROM country'
	mut params := []firebird.Value{}

	mut sorting := ''
	sorting = appendln(sorting, 'ORDER BY code ${get_sorting_order(p.order)}')

	if p.offset.is_set {
		sorting = appendln(sorting, 'OFFSET ? ROWS')
		params = arrays.concat(params, p.offset.v)
	}

	if p.fetch.is_set {
		sorting = appendln(sorting, 'FETCH NEXT ? ROWS ONLY')
		params = arrays.concat(params, p.fetch.v)
	}

	data := tx.execute('${query}${sorting}', ...params)!
	rows := data.rows()

	mut countries := []Country{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()
		code, _ := v[0].get_string()!
		region_id_bin := v[1].get_null_array_u8()!
		country := Country{
			code:          code
			region_id_bin: region_id_bin
		}
		countries[i] = country
	}

	count, _ := rows[0].values()[2].get_i64()!

	return countries, count
}
