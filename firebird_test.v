module peony

fn test_posix_new_line_end_of_text_file() {
	queries := get_schema_queries()
	assert queries.len > 0
	assert queries[queries.len - 1] != '\n'

	country_codes := get_country_codes()
	assert country_codes.len > 0
	assert country_codes[country_codes.len - 1] != '\n'

	currency_codes := get_currency_data()
	assert currency_codes.len > 0
	assert currency_codes[currency_codes.len - 1] != '\n'

	locale_codes := get_locale_codes()
	assert locale_codes.len > 0
	assert locale_codes[locale_codes.len - 1] != '\n'
}
