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

fn test_get_conditions() {
	mut c := []string{}
	assert get_conditions(c) == ''

	c = ['id IN ?', "name LIKE '%' || ? '%'"]
	assert get_conditions(c) == "id IN ? AND name LIKE '%' || ? '%'"
}

fn test_get_where_conditions() {
	mut c := []string{}
	assert get_where_conditions(c) == ''

	c = ['id IN ?', "name LIKE '%' || ? '%'"]
	assert get_where_conditions(c) == "\nWHERE id IN ? AND name LIKE '%' || ? '%'"
}
