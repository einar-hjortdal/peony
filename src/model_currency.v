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

fn (mut app App) retrieve_currencies(offset i32, fetch i32) ![]Currency {
	mut tx := app.fb.start_transaction(firebird.isolation_level_read_commited)!
	data := tx.execute('SELECT (id, code, includes_tax) FROM currency 
		OFFSET ? ROWS
		FETCH NEXT ? ROWS ONLY
		ORDER BY code ASC',
		offset, i32_or_max(fetch))!
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
