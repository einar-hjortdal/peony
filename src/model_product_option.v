module main

import arrays
import einar_hjortdal.firebird

struct ProductOptionTranslation {
	product_option_id string
	locale_code       string
	title             string
}

fn parse_product_option_translation(v []firebird.Value) !ProductOptionTranslation {
	product_option_id_bin, _ := v[0].get_array_u8()!
	locale_code, _ := v[1].get_string()!
	title, _ := v[2].get_string()!

	product_option_id := id_bin_to_string(product_option_id_bin)!

	return ProductOptionTranslation{
		product_option_id: product_option_id
		locale_code:       locale_code
		title:             title
	}
}

struct ProductOption {
	id         string
	created_at firebird.DateTime
	updated_at firebird.DateTime
	deleted_at firebird.DateTime @[omitempty]
	product_id string
mut:
	values       []ProductOptionValue
	translations []ProductOptionTranslation
}

fn parse_product_option(v []firebird.Value) !ProductOption {
	id_bin, _ := v[0].get_array_u8()!
	created_at, _ := v[1].get_date_time()!
	updated_at, _ := v[2].get_date_time()!
	deleted_at, _ := v[3].get_date_time()!
	product_id_bin, _ := v[4].get_array_u8()!

	id := id_bin_to_string(id_bin)!
	product_id := id_bin_to_string(product_id_bin)!

	return ProductOption{
		id:         id
		created_at: created_at
		updated_at: updated_at
		deleted_at: deleted_at
		product_id: product_id
	}
}

fn (mut app App) do_retrieve_product_option_translations(mut tx firebird.Transaction, option_ids_bin [][]u8) ![]ProductOptionTranslation {
	data := tx.execute('SELECT product_option_id, locale_code, title
		FROM product_option_translations
		WHERE id IN ${get_n_placeholders(i32(option_ids_bin.len))}',
		...option_ids_bin)!

	mut translations := []ProductOptionTranslation{}
	for i := 0; i < data.rows.len; i++ {
		translation := parse_product_option_translation(data.rows[i].values)!
		translations = arrays.concat(translations, translation)
	}

	return translations
}

struct ProductOptionValueTranslation {
	product_option_value_id string
	locale_code             string
	name                    string
}

fn parse_product_option_value_translation(v []firebird.Value) !ProductOptionValueTranslation {
	product_option_value_id_bin, _ := v[0].get_array_u8()!
	locale_code, _ := v[1].get_string()!
	name, _ := v[2].get_string()!

	product_option_value_id := id_bin_to_string(product_option_value_id_bin)!

	return ProductOptionValueTranslation{
		product_option_value_id: product_option_value_id
		locale_code:             locale_code
		name:                    name
	}
}

fn do_retrieve_product_option_value_translations(mut tx firebird.Transaction, option_value_ids_bin [][]u8) ![]ProductOptionValueTranslation {
	data := tx.execute('SELECT product_option_value_id, locale_code, name
	FROM product_option_value_translations
	WHERE product_option_value_id IN ${get_n_placeholders(i32(option_value_ids_bin.len))}',
		...option_value_ids_bin)!

	mut translations := []ProductOptionValueTranslation{}
	for i := 0; i < data.rows.len; i++ {
		translation := parse_product_option_value_translation(data.rows[i].values)!
		translations = arrays.concat(translations, translation)
	}

	return translations
}

struct ProductOptionValue {
	id         string
	created_at firebird.DateTime
	updated_at firebird.DateTime
	deleted_at firebird.DateTime @[omitempty]
	option_id  string
	variant_id string
mut:
	translations []ProductOptionValueTranslation
}

fn parse_product_option_value(v []firebird.Value) !ProductOptionValue {
	id_bin, _ := v[0].get_array_u8()!
	created_at, _ := v[1].get_date_time()!
	updated_at, _ := v[2].get_date_time()!
	deleted_at, _ := v[3].get_date_time()!
	option_id_bin, _ := v[4].get_array_u8()!
	variant_id_bin, _ := v[4].get_array_u8()!

	id := id_bin_to_string(id_bin)!
	option_id := id_bin_to_string(option_id_bin)!
	variant_id := id_bin_to_string(variant_id_bin)!

	return ProductOptionValue{
		id:         id
		created_at: created_at
		updated_at: updated_at
		deleted_at: deleted_at
		option_id:  option_id
		variant_id: variant_id
	}
}

fn do_retrieve_product_option_values(mut tx firebird.Transaction, option_ids_bin [][]u8) ![]ProductOptionValue {
	data := tx.execute('SELECT id, created_at, updated_at, deleted_at, product_id 
	FROM product_option_value
	WHERE option_id IN ${get_n_placeholders(i32(option_ids_bin.len))}',
		...option_ids_bin)!

	mut values := []ProductOptionValue{}
	for i := 0; i < data.rows.len; i++ {
		value := parse_product_option_value(data.rows[i].values)!
		values = arrays.concat(values, value)
	}

	return values
}
