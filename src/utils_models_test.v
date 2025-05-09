module main

fn test_get_columns() {
	columns := ['id', 'name', 'currency_code', 'tax_rate']
	v := get_columns(columns)
	assert v == 'id, name, currency_code, tax_rate'
}

fn test_get_placeholders() {
	columns := ['id', 'name', 'currency_code', 'tax_rate']
	v := get_placeholders(columns)
	assert v == '?, ?, ?, ?'
}
