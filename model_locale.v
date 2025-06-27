module main

import arrays
import einar_hjortdal.firebird

struct Locale {
	code string
}

fn parse_locale(v []firebird.Value) !Locale {
	code, _ := v[0].get_string()!

	return Locale{
		code: code
	}
}

fn (mut app App) retrieve_locales(p RetrieveLocalesParams) !([]Locale, i64) {
	query := 'SELECT code, COUNT(*) OVER() FROM locale'
	mut params := []firebird.Value{}
	mut sorting := ''
	sorting = appendln(sorting, 'ORDER BY code ${get_sorting_order(p.order)}')

	if p.offset.is_set {
		sorting = appendln(sorting, 'OFFSET ? ROWS')
		params = arrays.concat(params, p.offset.v)
	}

	sorting = appendln(sorting, 'FETCH NEXT ? ROWS ONLY')
	params = arrays.concat(params, get_fetch_amount(p.fetch))

	mut tx := app.start_transaction()!
	data := tx.execute('${query}${sorting}', ...params)!
	tx.rollback()!

	mut res := []Locale{len: data.rows.len}
	for i := 0; i < data.rows.len; i++ {
		res[i] = parse_locale(data.rows[i].values)!
	}

	mut count := i64(0)
	if res.len > 0 {
		c, _ := data.rows[0].values[1].get_i64()!
		count = c
	}

	return res, count
}
