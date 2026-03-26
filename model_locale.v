module peony

import arrays
import einar_hjortdal.firebird

struct Locale {
	id   ID
	code string
}

fn (l Locale) id() ID {
	return l.id
}

struct LocaleRetrieveParams {
	ids    ?[]ID
	offset i32
	fetch  i32
	order  string
}

fn conditions_locale_retrieve(p LocaleRetrieveParams) (string, []firebird.Value) {
	mut conditions := []string{}
	mut params := []firebird.Value{}

	if ids := p.ids {
		conditions = arrays.concat(conditions, 'id IN (${get_placeholders(ids)})')
		params = arrays.concat(params, ...workaround_24757(ids_bytes(ids)))
	}

	return get_where_conditions(conditions), params
}

fn model_locale_retrieve_count(mut tx firebird.Transaction, p LocaleRetrieveParams) !i64 {
	conditions, params := conditions_locale_retrieve(p)
	data := tx.execute('SELECT COUNT(*) FROM locale ${conditions}', ...params)!
	rows := data.rows()
	values := rows[0].values() // should always return one row
	count, _ := values[0].get_i64()! // should always return one column
	return count
}

fn model_locale_retrieve(mut tx firebird.Transaction, p LocaleRetrieveParams) ![]Locale {
	conditions, mut params := conditions_locale_retrieve(p)
	mut sorting := 'ORDER BY created_at ${p.order}
		OFFSET ? ROWS
		FETCH NEXT ? ROWS ONLY'
	params = arrays.concat(params, p.offset, p.fetch)

	query := 'SELECT id, code FROM locale ${conditions} ${sorting}'
	data := tx.execute(query, ...params)!
	rows := data.rows()

	mut locales := []Locale{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()

		id_bin, _ := v[0].get_array_u8()!
		code, _ := v[1].get_string()!

		id := id_from_bytes(id_bin)!

		locales[i] = Locale{
			id:   id
			code: code
		}
	}

	return locales
}

