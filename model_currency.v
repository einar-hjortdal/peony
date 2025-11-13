module peony

import arrays
import einar_hjortdal.firebird

struct Currency {
	code           string
	decimal_digits firebird.NullI32
}

fn conditions_currency_retrieve(p RetrieveCurrenciesParams) (string, []firebird.Value) {
	mut conditions := []string{}
	mut params := []firebird.Value{}

	if p.codes.is_set {
		// workaround_24757() but for strings
		mut c := []firebird.Value{len: p.codes.v.len, init: firebird.Value(firebird.Null{})}
		for i := 0; i < p.codes.v.len; i++ {
			c[i] = firebird.Value(p.codes.v[i])
		}
		conditions = arrays.concat(conditions, 'WHERE code IN (${get_placeholders(p.codes.v)})')
		// v: ['EUR']
		// firebird.Value(5395781)
		// params = arrays.concat(params, ...p.code.v)
		params = arrays.concat(params, ...c)
	}

	return get_where_conditions(conditions), params
}

fn model_currency_retrieve_count(mut tx firebird.Transaction, p RetrieveCurrenciesParams) !i64 {
	conditions, params := conditions_currency_retrieve(p)
	data := tx.execute('SELECT COUNT(*) OVER() FROM currency ${conditions}', ...params)!
	rows := data.rows()
	values := rows[0].values() // should always return one row
	count, _ := values[0].get_i64()! // should always return one column
	return count
}

fn model_currency_retrieve(mut tx firebird.Transaction, p RetrieveCurrenciesParams) ![]Currency {
	query := 'SELECT code, decimal_digits FROM currency'
	conditions, mut params := conditions_currency_retrieve(p)

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

	data := tx.execute('${query}${conditions}${sorting}', ...params)!
	rows := data.rows()

	mut currencies := []Currency{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()

		code, _ := v[0].get_string()!
		decimal_digits := v[1].get_null_i32()!

		currencies[i] = Currency{
			code:           code
			decimal_digits: decimal_digits
		}
	}

	return currencies
}
