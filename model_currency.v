module peony

import arrays
import einar_hjortdal.firebird

struct Currency {
	code           string
	decimal_digits firebird.NullI32
}

struct CurrencyRetrieveParams {
	codes  ?[]string
	offset i32
	fetch  i32
	order  string
}

fn conditions_currency_retrieve(p CurrencyRetrieveParams) (string, []firebird.Value) {
	mut conditions := []string{}
	mut params := []firebird.Value{}

	if codes := p.codes {
		// workaround_24757() but for strings
		mut c := []firebird.Value{len: codes.len, init: firebird.Null{}}
		for i := 0; i < codes.len; i++ {
			c[i] = firebird.Value(codes[i])
		}
		conditions = arrays.concat(conditions, 'code IN (${get_placeholders(codes)})')
		params = arrays.concat(params, ...c)
	}

	return get_where_conditions(conditions), params
}

fn model_currency_retrieve_count(mut tx firebird.Transaction, p CurrencyRetrieveParams) !i64 {
	conditions, params := conditions_currency_retrieve(p)
	data := tx.execute('SELECT COUNT(*) FROM currency ${conditions}', ...params)!
	rows := data.rows()
	values := rows[0].values() // should always return one row
	count, _ := values[0].get_i64()! // should always return one column
	return count
}

fn model_currency_retrieve(mut tx firebird.Transaction, p CurrencyRetrieveParams) ![]Currency {
	conditions, mut params := conditions_currency_retrieve(p)

	mut sorting := 'ORDER BY created_at ${p.order} 
		OFFSET ? ROWS
		FETCH NEXT ? ROWS ONLY'
	params = arrays.concat(params, p.offset, p.fetch)

	query := 'SELECT code, decimal_digits FROM currency ${conditions} ${sorting}'
	data := tx.execute(query, ...params)!
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

