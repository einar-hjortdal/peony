module main

fn test_get_schema_queries() {
	queries := get_schema_queries()
	len := queries.len
	assert len > 0
	assert queries[len - 1] != '\n'
}

fn test_get_codes() {
	country_codes := get_country_codes()
	assert country_codes.len > 0
	assert country_codes[country_codes.len - 1] != '\n'

	currency_codes := get_currency_codes()
	assert currency_codes.len > 0
	assert currency_codes[currency_codes.len - 1] != '\n'

	locale_codes := get_locale_codes()
	assert locale_codes.len > 0
	assert locale_codes[locale_codes.len - 1] != '\n'
}
