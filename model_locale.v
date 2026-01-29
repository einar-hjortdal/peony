module peony

import arrays
import einar_hjortdal.firebird

struct Locale {
	id     string
	id_bin []u8
	code   string
}

fn conditions_locale_retrieve(ph LocaleRetrieveParamsHygienised) (string, []firebird.Value) {
	mut conditions := []string{}
	mut params := []firebird.Value{}

	if ph.ids.is_set {
		conditions = arrays.concat(conditions, 'id IN (${get_placeholders(ph.ids_bin)})')
		params = arrays.concat(params, ...workaround_24757(ph.ids_bin))
	}

	return get_where_conditions(conditions), params
}

fn model_locale_retrieve_count(mut tx firebird.Transaction, ph LocaleRetrieveParamsHygienised) !i64 {
	conditions, params := conditions_locale_retrieve(ph)
	data := tx.execute('SELECT COUNT(*) FROM locale ${conditions}', ...params)!
	rows := data.rows()
	values := rows[0].values() // should always return one row
	count, _ := values[0].get_i64()! // should always return one column
	return count
}

fn model_locale_retrieve(mut tx firebird.Transaction, ph LocaleRetrieveParamsHygienised) ![]Locale {
	conditions, mut params := conditions_locale_retrieve(ph)
	mut sorting := 'ORDER BY code ${get_sorting_order(ph.order)}'

	if ph.offset.is_set {
		sorting = appendln(sorting, 'OFFSET ? ROWS')
		params = arrays.concat(params, ph.offset.v)
	}

	sorting = appendln(sorting, 'FETCH NEXT ? ROWS ONLY')
	if ph.fetch.is_set {
		params = arrays.concat(params, ph.fetch.v)
	} else {
		params = arrays.concat(params, max_fetch)
	}

	data := tx.execute('SELECT id, code FROM locale ${conditions} ${sorting}', ...params)!
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
