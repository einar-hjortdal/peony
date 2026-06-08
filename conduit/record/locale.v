module record

import arrays
import einar_hjortdal.firebird

pub struct Locale {
pub:
	id   ID
	code string
}

pub fn (l Locale) id() ID {
	return l.id
}

pub struct LocaleRetrieveParams {
pub:
	ids    ?[]ID
	offset i32
	fetch  i32
	order  string
}

pub fn locale_retrieve_conditions(p LocaleRetrieveParams) (string, []firebird.Value) {
	mut conditions := []string{}
	mut params := []firebird.Value{}

	if ids := p.ids {
		conditions = arrays.concat(conditions, 'id IN (${get_placeholders(ids)})')
		params = arrays.concat(params, ...ids_bytes(ids))
	}

	return get_where_conditions(conditions), params
}

pub fn locale_retrieve_count(mut tx firebird.Transaction, p LocaleRetrieveParams) !i64 {
	conditions, params := locale_retrieve_conditions(p)
	data := tx.execute('SELECT COUNT(*) FROM locale ${conditions}', ...params)!
	rows := data.rows()
	values := rows[0].values() // should always return one row
	count, _ := values[0].get_i64()! // should always return one column
	return count
}

pub fn locale_retrieve(mut tx firebird.Transaction, p LocaleRetrieveParams) ![]Locale {
	conditions, mut params := locale_retrieve_conditions(p)
	mut sorting := 'ORDER BY code ${p.order}
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
