module peony

import arrays
import einar_hjortdal.firebird

struct Currency {
	code           string
	decimal_digits firebird.NullI32
	includes_tax   bool
}

fn parse_currency(v []firebird.Value) !Currency {
	code, _ := v[0].get_string()!
	decimal_digits := v[1].get_null_i32()!
	includes_tax, _ := v[2].get_bool()!

	return Currency{
		code:           code
		decimal_digits: decimal_digits
		includes_tax:   includes_tax
	}
}

fn (mut app App) retrieve_currencies(mut tx firebird.Transaction, p RetrieveCurrenciesParams) !([]Currency, i64) {
	query := 'SELECT code, decimal_digits, includes_tax, COUNT(*) OVER() FROM currency'
	mut params := []firebird.Value{}
	mut conditions := ''
	if p.code.is_set {
		// workaround_24757() but for strings
		mut c := []firebird.Value{len: p.code.v.len, init: firebird.Value(firebird.Null{})}
		for i := 0; i < p.code.v.len; i++ {
			c[i] = firebird.Value(p.code.v[i])
		}
		conditions = appendln(conditions, 'WHERE code IN (${get_n_placeholders(i32(p.code.v.len))})')
		// v: ['EUR']
		// firebird.Value(5395781)
		// params = arrays.concat(params, ...p.code.v)
		params = arrays.concat(params, ...c)
	}

	if p.includes_tax.is_set {
		conditions = appendln(conditions, 'WHERE includes_tax = ?')
		params = arrays.concat(params, p.includes_tax.v)
	}

	mut sorting := ''
	sorting = appendln(sorting, 'ORDER BY code ${get_sorting_order(p.order)}')

	if p.offset.is_set {
		sorting = appendln(sorting, 'OFFSET ? ROWS')
		params = arrays.concat(params, p.offset.v)
	}

	sorting = appendln(sorting, 'FETCH NEXT ? ROWS ONLY')
	params = arrays.concat(params, get_fetch_amount(p.fetch))

	data := tx.execute('${query}${conditions}${sorting}', ...params)!
	rows := data.rows()

	mut res := []Currency{len: rows.len}
	for i := 0; i < rows.len; i++ {
		res[i] = parse_currency(rows[i].values())!
	}

	mut count := i64(0)
	if res.len > 0 {
		c, _ := rows[0].values()[3].get_i64()!
		count = c
	}

	return res, count
}

fn (mut app App) update_currency(mut tx firebird.Transaction, code string, p NewCurrencyData) ! {
	tx.execute('UPDATE currency SET includes_tax = ? WHERE code = ?', p.includes_tax,
		code)!
}
