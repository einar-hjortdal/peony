module main

import arrays
import einar_hjortdal.firebird

struct ProductOptionValueTranslation {
	product_option_value_id     string
	product_option_value_id_bin []u8
	locale_id                   string
	locale_id_bin               []u8
	name                        string
}

fn parse_product_option_value_translation(v []firebird.Value) !ProductOptionValueTranslation {
	product_option_value_id_bin, _ := v[0].get_array_u8()!
	locale_id_bin, _ := v[1].get_array_u8()!
	name, _ := v[2].get_string()!

	product_option_value_id := id_bin_to_string(product_option_value_id_bin)!
	locale_id := id_bin_to_string(locale_id_bin)!

	return ProductOptionValueTranslation{
		product_option_value_id:     product_option_value_id
		product_option_value_id_bin: product_option_value_id_bin
		locale_id:                   locale_id
		locale_id_bin:               locale_id_bin
		name:                        name
	}
}

fn do_retrieve_product_option_value_translations(mut tx firebird.Transaction, option_value_ids_bin [][]u8) ![]ProductOptionValueTranslation {
	data := tx.execute('SELECT product_option_value_id, locale_id, name
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
	id             string
	id_bin         []u8
	option_id      string
	option_id_bin  []u8
	variant_id     string
	variant_id_bin []u8
mut:
	translations []ProductOptionValueTranslation
}

fn parse_product_option_value(v []firebird.Value) !ProductOptionValue {
	id_bin, _ := v[0].get_array_u8()!
	option_id_bin, _ := v[1].get_array_u8()!
	variant_id_bin, _ := v[2].get_array_u8()!

	id := id_bin_to_string(id_bin)!
	option_id := id_bin_to_string(option_id_bin)!
	variant_id := id_bin_to_string(variant_id_bin)!

	return ProductOptionValue{
		id:             id
		id_bin:         id_bin
		option_id:      option_id
		option_id_bin:  option_id_bin
		variant_id:     variant_id
		variant_id_bin: variant_id_bin
	}
}

fn do_retrieve_product_option_values(mut tx firebird.Transaction, option_ids_bin [][]u8) ![]ProductOptionValue {
	data := tx.execute('SELECT id, product_id, variant_id FROM product_option_value
	WHERE option_id IN ${get_n_placeholders(i32(option_ids_bin.len))}',
		...option_ids_bin)!

	mut values := []ProductOptionValue{}
	for i := 0; i < data.rows.len; i++ {
		value := parse_product_option_value(data.rows[i].values)!
		values = arrays.concat(values, value)
	}

	return values
}

struct ProductOptionTranslation {
	product_option_id     string
	product_option_id_bin []u8
	locale_id             string
	locale_id_bin         []u8
	title                 string
}

fn parse_product_option_translation(v []firebird.Value) !ProductOptionTranslation {
	product_option_id_bin, _ := v[0].get_array_u8()!
	locale_id_bin, _ := v[1].get_array_u8()!
	title, _ := v[2].get_string()!

	product_option_id := id_bin_to_string(product_option_id_bin)!
	locale_id := id_bin_to_string(locale_id_bin)!

	return ProductOptionTranslation{
		product_option_id:     product_option_id
		product_option_id_bin: product_option_id_bin
		locale_id:             locale_id
		locale_id_bin:         locale_id_bin
		title:                 title
	}
}

fn do_retrieve_product_option_translations(mut tx firebird.Transaction, option_ids_bin [][]u8) ![]ProductOptionTranslation {
	data := tx.execute('SELECT product_option_id, locale_id, title
		FROM product_option_translations
		WHERE id IN (${get_n_placeholders(i32(option_ids_bin.len))})',
		...workaround_24757(option_ids_bin))!

	mut translations := []ProductOptionTranslation{}
	for i := 0; i < data.rows.len; i++ {
		translation := parse_product_option_translation(data.rows[i].values)!
		translations = arrays.concat(translations, translation)
	}

	return translations
}

struct ProductOption {
	id             string
	id_bin         []u8
	product_id     string
	product_id_bin []u8
mut:
	values       []ProductOptionValue
	translations []ProductOptionTranslation
}

fn parse_product_option(v []firebird.Value) !ProductOption {
	id_bin, _ := v[0].get_array_u8()!
	product_id_bin, _ := v[1].get_array_u8()!

	id := id_bin_to_string(id_bin)!
	product_id := id_bin_to_string(product_id_bin)!

	return ProductOption{
		id:             id
		id_bin:         id_bin
		product_id:     product_id
		product_id_bin: product_id_bin
	}
}

fn do_retrieve_product_options(mut tx firebird.Transaction, ids_bin [][]u8) ![]ProductOption {
	mut data := tx.execute('SELECT id, product_id FROM product_option
			WHERE id IN (${get_n_placeholders(i32(ids_bin.len))})',
		...workaround_24757(ids_bin))!

	if data.rows.len == 0 {
		return []ProductOption{}
	}

	mut options := []ProductOption{len: data.rows.len}
	mut option_ids_bin := [][]u8{len: data.rows.len}
	for i := 0; i < data.rows.len; i++ {
		options[i] = parse_product_option(data.rows[i].values)!
		option_ids_bin[i] = options[i].id_bin
	}

	translations := do_retrieve_product_option_translations(mut tx, option_ids_bin)!

	for i := 0; i < translations.len; i++ {
		for k := 0; k < options.len; k++ {
			if translations[i].product_option_id == options[k].id {
				options[k].translations = arrays.concat(options[k].translations, translations[i])
			}
		}
	}

	return options
}

fn (mut app App) do_update_product_options(mut tx firebird.Transaction, product_id_bin []u8, o []ProductOptionData) ! {
	mut to_update := []ProductOptionData{}
	mut to_create := []ProductOptionData{}
	for i := 0; i < o.len; i++ {
		if _ := o[i].id {
			to_update = arrays.concat(to_update, o[i])
		} else {
			to_create = arrays.concat(to_create, o[i])
		}
	}

	// TODO merge for to_update

	mut ids_bin := [][]u8{len: to_create.len}
	mut params := []firebird.Value{len: to_create.len * 2, init: firebird.Value(firebird.Null{})}
	mut cte_table := ''
	for i := 0; i < to_create.len; i++ {
		_, id_bin := app.new_id()!
		ids_bin[i] = id_bin

		cte_table = appendln(cte_table, 'SELECT
			CAST(? AS BINARY(16)) AS o_id,
			CAST(? AS BINARY(16)) AS p_id
			FROM RDB\$DATABASE')

		params[2 * i] = id_bin
		params[2 * i + 1] = product_id_bin

		if i < to_create.len - 1 {
			cte_table = appendln(cte_table, 'UNION ALL')
		}
	}

	tx.execute('WITH new_options AS (${cte_table})
		INSERT INTO product_option (id, product_id) SELECT o_id, p_id FROM new_options',
		...params)!

	mut cte_lines := []string{}
	params = []firebird.Value{}
	for i := 0; i < to_create.len; i++ {
		id_bin := ids_bin[i]
		if translations := to_create[i].translations {
			for t := 0; t < translations.len; t++ {
				cte_lines = arrays.concat(cte_lines, 'SELECT
					CAST(? AS BINARY(16)) AS o_id,
					CAST(? AS BINARY(16)) AS l_id,
					CAST(? AS VARCHAR(63)) AS t
					FROM RDB\$DATABASE')

				locale_id_bin := id_string_to_bin(translations[t].locale_id)!
				params = arrays.concat(params, id_bin, locale_id_bin, translations[t].title)
			}
		}
	}

	tx.execute('WITH new_translations AS (${cte_lines.join('\nUNION ALL\n')})
		INSERT INTO product_option_translations (product_option_id, locale_id, title)
		SELECT o_id, l_id, t FROM new_translations',
		...params)!

	// TODO handle product_option_value and product_option_value_translations
}
