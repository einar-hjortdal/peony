module peony

import arrays
import einar_hjortdal.firebird

struct Locale {
	id     string
	id_bin []u8
	code   string
}

fn parse_locale(v []firebird.Value) !Locale {
	id_bin, _ := v[0].get_array_u8()!
	code, _ := v[1].get_string()!

	id := id_bin_to_string(id_bin)!

	return Locale{
		id:     id
		id_bin: id_bin
		code:   code
	}
}

fn model_retrieve_locales(mut tx firebird.Transaction, p RetrieveLocalesParams) !([]Locale, i64) {
	query := 'SELECT id, code, COUNT(*) OVER() FROM locale'
	mut params := []firebird.Value{}
	mut sorting := ''
	sorting = appendln(sorting, 'ORDER BY code ${get_sorting_order(p.order)}')

	if p.offset.is_set {
		sorting = appendln(sorting, 'OFFSET ? ROWS')
		params = arrays.concat(params, p.offset.v)
	}

	sorting = appendln(sorting, 'FETCH NEXT ? ROWS ONLY')
	params = arrays.concat(params, get_fetch_amount(p.fetch))

	data := tx.execute('${query}${sorting}', ...params)!
	rows := data.rows()

	mut res := []Locale{len: rows.len}
	for i := 0; i < rows.len; i++ {
		res[i] = parse_locale(rows[i].values())!
	}

	mut count := i64(0)
	if res.len > 0 {
		c, _ := rows[0].values()[2].get_i64()!
		count = c
	}

	return res, count
}
