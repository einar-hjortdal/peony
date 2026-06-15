module record

import arrays
import einar_hjortdal.firebird

pub struct Currency {
pub:
	code           string
	decimal_digits ?i32
}

pub struct CurrencyRetrieveParams {
pub:
	codes  ?[]string
	offset i32
	fetch  i32
	order  string
}

pub fn currency_retrieve_conditions(p CurrencyRetrieveParams) (string, []firebird.Value) {
	mut conditions := []string{}
	mut params := []firebird.Value{}

	if codes := p.codes {
		conditions = arrays.concat(conditions, 'code IN (${get_placeholders(codes)})')
		params = arrays.concat(params, ...codes)
	}

	return get_where_conditions(conditions), params
}

pub fn currency_retrieve_count(mut tx firebird.ClientTransaction, p CurrencyRetrieveParams) !i64 {
	conditions, params := currency_retrieve_conditions(p)
	data := tx.execute('SELECT COUNT(*) FROM currency ${conditions}', ...params)!
	rows := data.rows()
	values := rows[0].values() // should always return one row
	count, _ := values[0].get_i64()! // should always return one column
	return count
}

pub fn currency_retrieve(mut tx firebird.ClientTransaction, p CurrencyRetrieveParams) ![]Currency {
	conditions, mut params := currency_retrieve_conditions(p)

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
			decimal_digits: decimal_digits.none_value()
		}
	}

	return currencies
}
