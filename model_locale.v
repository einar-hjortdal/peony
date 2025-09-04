module peony

import arrays
import einar_hjortdal.firebird

struct Locale {
	id     string
	id_bin []u8
	code   string
}

fn model_locale_retrieve_count(mut tx firebird.Transaction, p LocaleRetrieveParams) !i64 {
	data := tx.execute('SELECT COUNT(*) FROM locale')!
	rows := data.rows()
	values := rows[0].values() // should always return one row
	count, _ := values[0].get_i64()! // should always return one column
	return count
}

fn model_locale_retrieve(mut tx firebird.Transaction, p LocaleRetrieveParams) ![]Locale {
	mut params := []firebird.Value{}
	mut sorting := 'ORDER BY code ${get_sorting_order(p.order)}'

	if p.offset.is_set {
		sorting = appendln(sorting, 'OFFSET ? ROWS')
		params = arrays.concat(params, p.offset.v)
	}

	if p.fetch.is_set {
		sorting = appendln(sorting, 'FETCH NEXT ? ROWS ONLY')
		params = arrays.concat(params, p.fetch.v)
	}

	data := tx.execute('SELECT id, code FROM locale ${sorting}', ...params)!
	rows := data.rows()

	mut locales := []Locale{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()

		id_bin, _ := v[0].get_array_u8()!
		code, _ := v[1].get_string()!

		id := id_bin_to_string(id_bin)!

		locales[i] = Locale{
			id:     id
			id_bin: id_bin
			code:   code
		}
	}

	return locales
}
