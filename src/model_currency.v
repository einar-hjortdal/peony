module main

import einar_hjortdal.firebird

struct Currency {
	id           string
	code         string
	includes_tax bool
}

fn parse_currency_data(v []firebird.Value) !Currency {
	id, _ := firebird.get_string(v[0])!
	code, _ := firebird.get_string(v[1])!
	includes_tax, _ := firebird.get_bool(v[2])!

	return Currency{
		id:           id
		code:         code
		includes_tax: includes_tax
	}
}

fn (mut app App) retrieve_currencies() ![]Currency {
	// TODO
}

fn (mut app App) retrieve_currency_by_id(id string) !Currency {
	mut tx := app.fb.start_transaction(firebird.isolation_level_read_commited)!
	res := tx.execute('SELECT (UUID_TO_CHAR(id), code, includes_tax)	FROM currency WHERE id = ?',
		id)!
	tx.rollback()!

	if res.rows.len == 0 {
		return error(format_error_message('No currency found'))
	}

	return parse_currency_data(res.rows[0].values)!
}

fn (mut app App) retrieve_currency_by_code(code string) !Currency {
	mut tx := app.fb.start_transaction(firebird.isolation_level_read_commited)!
	res := tx.execute('SELECT (UUID_TO_CHAR(id), code, includes_tax)	FROM currency WHERE code = ?',
		code)!
	tx.rollback()!

	if res.rows.len == 0 {
		return error(format_error_message('No currency found'))
	}

	return parse_currency_data(res.rows[0].values)!
}

struct NewCurrencyData {
	includes_tax bool
}

fn (mut app App) update_currency(id string, data NewCurrencyData) ! {
	mut tx := app.fb.start_transaction(firebird.isolation_level_read_commited)!
	tx.execute('UPDATE currency SET includes_tax = ? WHERE id = CHAR_TO_UUID(?)', data.includes_tax,
		id)!
	tx.commit()!
}
