module main

import arrays
import einar_hjortdal.firebird

struct Currency {
	code         string
	includes_tax bool
}

fn parse_currency(v []firebird.Value) !Currency {
	code, _ := v[1].get_string()!
	includes_tax, _ := v[2].get_bool()!

	return Currency{
		code:         code
		includes_tax: includes_tax
	}
}

struct RetrieveCurrenciesParams {
	code         ZeroString
	includes_tax ZeroBool
	offset       ZeroI32
	fetch        ZeroI32
	order        ZeroString
}

fn extract_retrieve_currencies_params(m map[string]string) RetrieveCurrenciesParams {
	return RetrieveCurrenciesParams{
		code:         zero_string(m, 'code')
		includes_tax: zero_bool(m, 'includes_tax')
		offset:       zero_i32(m, 'offset')
		fetch:        zero_i32(m, 'fetch')
		order:        zero_string(m, 'order')
	}
}

fn (mut app App) retrieve_currencies(p RetrieveCurrenciesParams) ![]Currency {
	query := 'SELECT (code, includes_tax) FROM currency'
	mut params := []firebird.Value{}
	mut conditions := ''
	if p.includes_tax.is_set {
		conditions = appendln(conditions, 'WHERE includes_tax = ?')
		params = arrays.concat(params, p.includes_tax.v)
	}

	mut sorting := ''
	if p.offset.is_set {
		sorting = appendln(sorting, 'OFFSET ? ROWS')
		params = arrays.concat(params, p.offset.v)
	}

	sorting = appendln(sorting, 'FETCH NEXT ? ROWS ONLY')
	params = arrays.concat(params, get_fetch_amount(p.fetch))

	sorting = appendln(sorting, 'ORDER BY product_id, variant_rank ${get_sorting_order(p.order)}')

	mut tx := app.fb.start_transaction(firebird.isolation_level_read_commited)!
	data := tx.execute('${query}${conditions}${sorting}', ...params)!
	tx.rollback()!

	mut res := []Currency{}
	for i := 0; i < data.rows.len; i++ {
		currency := parse_currency(data.rows[i].values)!
		res = arrays.concat(res, currency)
	}
	return res
}

fn (mut app App) retrieve_currency_by_code(code string) !Currency {
	mut tx := app.fb.start_transaction(firebird.isolation_level_read_commited)!
	res := tx.execute('SELECT (code, includes_tax)	FROM currency WHERE code = ?', code)!
	tx.rollback()!

	if res.rows.len == 0 {
		return error(format_error_message('No currency found'))
	}

	return parse_currency(res.rows[0].values)!
}

struct NewCurrencyData {
	includes_tax bool
}

fn (mut app App) update_currency(code string, data NewCurrencyData) ! {
	mut tx := app.fb.start_transaction(firebird.isolation_level_read_commited)!
	tx.execute('UPDATE currency SET includes_tax = ? WHERE code = ?', data.includes_tax,
		code)!
	tx.commit()!
}
