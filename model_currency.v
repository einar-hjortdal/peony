module peony

import arrays
import einar_hjortdal.firebird

struct Currency {
	code           string
	decimal_digits firebird.NullI32
}

// TODO separate query for count
fn (mut app App) retrieve_currencies(mut tx firebird.Transaction, p RetrieveCurrenciesParams) !([]Currency, i64) {
	query := 'SELECT code, decimal_digits, COUNT(*) OVER() FROM currency'
	mut params := []firebird.Value{}
	mut conditions := ''
	if p.code.is_set {
		// workaround_24757() but for strings
		mut c := []firebird.Value{len: p.code.v.len, init: firebird.Value(firebird.Null{})}
		for i := 0; i < p.code.v.len; i++ {
			c[i] = firebird.Value(p.code.v[i])
		}
		conditions = appendln(conditions, 'WHERE code IN (${get_placeholders(p.code.v)})')
		// v: ['EUR']
		// firebird.Value(5395781)
		// params = arrays.concat(params, ...p.code.v)
		params = arrays.concat(params, ...c)
	}

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

	mut res := []Currency{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()

		code, _ := v[0].get_string()!
		decimal_digits := v[1].get_null_i32()!

		res[i] = Currency{
			code:           code
			decimal_digits: decimal_digits
		}
	}

	mut count := i64(0)
	if res.len > 0 {
		v := rows[0].values()
		c, _ := v[2].get_i64()!
		count = c
	}

	return res, count
}
