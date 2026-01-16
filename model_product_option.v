module peony

import einar_hjortdal.firebird

struct ProductOptionValueTranslation {
	option_value_id     string
	option_value_id_bin []u8
	locale_id           string
	locale_id_bin       []u8
	name                string
}

fn model_product_option_value_translations_retrieve(mut tx firebird.Transaction, product_option_value_ids_bin [][]u8) ![]ProductOptionValueTranslation {
	data := tx.execute('SELECT product_option_value_id, locale_id, name
	FROM product_option_value_translations
	WHERE product_option_value_id IN (${get_placeholders(product_option_value_ids_bin)})',
		...workaround_24757(product_option_value_ids_bin))!

	rows := data.rows()

	mut translations := []ProductOptionValueTranslation{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()

		option_value_id_bin, _ := v[0].get_array_u8()!
		locale_id_bin, _ := v[1].get_array_u8()!
		name, _ := v[2].get_string()!

		option_value_id := id_bin_to_string(option_value_id_bin)!
		locale_id := id_bin_to_string(locale_id_bin)!

		translations[i] = ProductOptionValueTranslation{
			option_value_id:     option_value_id
			option_value_id_bin: option_value_id_bin
			locale_id:           locale_id
			locale_id_bin:       locale_id_bin
			name:                name
		}
	}
	return translations
}

struct ProductOptionValue {
	id            string
	id_bin        []u8
	option_id     string
	option_id_bin []u8
	name          string
mut:
	translations []ProductOptionValueTranslation
}

fn model_product_option_value_create(mut tx firebird.Transaction, product_option_id_bin []u8, product_option_value_id_bin []u8) ! {
	tx.execute('INSERT INTO product_option_value (id, option_id) VALUES (?, ?)', product_option_value_id_bin,
		product_option_id_bin)!
}

fn model_product_option_values_retrieve(mut tx firebird.Transaction, product_option_ids_bin [][]u8) ![]ProductOptionValue {
	data := tx.execute('SELECT id, option_id, name FROM product_option_value
		WHERE option_id IN (${get_placeholders(product_option_ids_bin)})',
		...workaround_24757(product_option_ids_bin))!

	rows := data.rows()

	mut product_option_values := []ProductOptionValue{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()

		id_bin, _ := v[0].get_array_u8()!
		option_id_bin, _ := v[1].get_array_u8()!
		name, _ := v[2].get_string()!

		id := id_bin_to_string(id_bin)!
		option_id := id_bin_to_string(option_id_bin)!

		product_option_values[i] = ProductOptionValue{
			id:            id
			id_bin:        id_bin
			option_id:     option_id
			option_id_bin: option_id_bin
			name:          name
		}
	}

	return product_option_values
}

struct ProductOptionValueUpdateParams {
	name string
}

fn model_product_option_value_update(mut tx firebird.Transaction, product_option_value_id_bin []u8, p ProductOptionValueUpdateParams) ! {
	tx.execute('UPDATE product_option_value SET name = ? WHERE id = ?', p.name, product_option_value_id_bin)!
}

struct ProductOptionValueTranslationUpdateParams {
	locale_id_bin []u8
	name          string
}

fn model_product_option_value_translations_update(mut tx firebird.Transaction, product_option_value_id_bin []u8, p []ProductOptionValueTranslationUpdateParams) ! {
	tx.execute('DELETE FROM product_option_value_translations WHERE product_option_value_id = ?',
		product_option_value_id_bin)!

	mut src := []string{len: p.len}
	mut params := []firebird.Value{len: p.len * 3, init: firebird.Null{}}
	for i := 0; i < p.len; i++ {
		translation := p[i]
		src[i] = 'SELECT
				CAST(? AS BINARY(16)) AS product_option_value_id,
				CAST(? AS BINARY(16)) AS locale_id,
				CAST(? AS VARCHAR(63)) AS name
				FROM RDB\$DATABASE'
		params[i * 3] = product_option_value_id_bin
		params[i * 3 + 1] = translation.locale_id_bin
		params[i * 3 + 2] = translation.name
	}

	tx.execute('INSERT INTO product_option_value_translations (product_option_value_id, locale_id, name)
		${get_merge_source(src)}',
		...params)!
}

fn model_product_option_value_delete(mut tx firebird.Transaction, product_option_value_id_bin []u8) ! {
	tx.execute('DELETE FROM product_option_value WHERE id = ?', product_option_value_id_bin)!
}

struct ProductOptionTranslation {
	product_option_id     string
	product_option_id_bin []u8
	locale_id             string
	locale_id_bin         []u8
	title                 string
}

fn model_product_option_translations_retrieve(mut tx firebird.Transaction, product_option_ids_bin [][]u8) ![]ProductOptionTranslation {
	data := tx.execute('SELECT product_option_id, locale_id, title
		FROM product_option_translations
		WHERE product_option_id IN (${get_placeholders(product_option_ids_bin)})',
		...workaround_24757(product_option_ids_bin))!

	rows := data.rows()

	mut translations := []ProductOptionTranslation{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()

		product_option_id_bin, _ := v[0].get_array_u8()!
		locale_id_bin, _ := v[1].get_array_u8()!
		title, _ := v[2].get_string()!

		product_option_id := id_bin_to_string(product_option_id_bin)!
		locale_id := id_bin_to_string(locale_id_bin)!

		translations[i] = ProductOptionTranslation{
			product_option_id:     product_option_id
			product_option_id_bin: product_option_id_bin
			locale_id:             locale_id
			locale_id_bin:         locale_id_bin
			title:                 title
		}
	}

	return translations
}

struct ProductOption {
	id             string
	id_bin         []u8
	product_id     string
	product_id_bin []u8
	title          string
mut:
	values       []ProductOptionValue
	translations []ProductOptionTranslation
}

fn model_product_options_retrieve_by_product_ids(mut tx firebird.Transaction, product_ids_bin [][]u8) ![]ProductOption {
	mut data := tx.execute('SELECT id, product_id, title FROM product_option
		WHERE product_id IN (${get_placeholders(product_ids_bin)})',
		...workaround_24757(product_ids_bin))!

	rows := data.rows()

	if rows.len == 0 {
		return []ProductOption{}
	}

	mut options := []ProductOption{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()

		id_bin, _ := v[0].get_array_u8()!
		product_id_bin, _ := v[1].get_array_u8()!
		title, _ := v[2].get_string()!

		id := id_bin_to_string(id_bin)!
		product_id := id_bin_to_string(product_id_bin)!

		options[i] = ProductOption{
			id:             id
			id_bin:         id_bin
			product_id:     product_id
			product_id_bin: product_id_bin
			title:          title
		}
	}
	return options
}

fn model_product_option_create(mut tx firebird.Transaction, product_id_bin []u8, product_option_id_bin []u8, product_option_value_ids_bin [][]u8, ph ProductOptionCreateRequestHygienised) ! {
	tx.execute('INSERT INTO product_option (id, product_id, title) VALUES (?, ?, ?)',
		product_id_bin, product_option_id_bin, ph.title)!

	if translations := ph.translations {
		mut src := []string{len: translations.len}
		mut params := []firebird.Value{len: translations.len * 3, init: firebird.Null{}}
		for i := 0; i < translations.len; i++ {
			translation := translations[i]
			src[i] = 'SELECT
			CAST(? AS BINARY(16)) AS product_option_id,
			CAST(? AS BINARY(16)) AS locale_id,
			CAST(? AS VARCHAR(63)) AS title
			FROM RDB\$DATABASE'

			params[i * 3] = product_option_id_bin
			params[i * 3 + 1] = translation.locale_id_bin
			params[i * 3 + 2] = translation.title
		}

		tx.execute('INSERT INTO product_option_translations (product_option_id, locale_id, title) ${get_merge_source(src)}',
			...params)!
	}

	mut src := []string{len: ph.values.len}
	mut params := []firebird.Value{len: ph.values.len * 2, init: firebird.Null{}}
	for i := 0; i < ph.values.len; i++ {
		src[i] = 'SELECT
			CAST(? AS BINARY(16)) AS id,
			CAST(? AS BINARY(16)) AS option_id
			FROM RDB\$DATABASE'
		params[i * 2] = product_option_value_ids_bin[i]
		params[i * 2 + 1] = product_option_id_bin
	}

	tx.execute('INSERT INTO product_option_value (id, option_id) ${get_merge_source(src)}',
		...params)!

	mut n_translations := 0
	for i := 0; i < ph.values.len; i++ {
		value := ph.values[i]
		if translations := value.translations {
			n_translations += translations.len
		}
	}

	if n_translations > 0 {
		src = []string{len: n_translations}
		params = []firebird.Value{len: n_translations * 3, init: firebird.Null{}}
		mut current_translation := 0
		for i := 0; i < ph.values.len; i++ {
			product_option_value := ph.values[i]
			product_option_value_id_bin := product_option_value_ids_bin[i]
			if translations := product_option_value.translations {
				for j := 0; j < translations.len; j++ {
					translation := translations[j]
					src[current_translation] = 'SELECT
						CAST(? AS BINARY(16)) AS product_option_value_id,
						CAST(? AS BINARY(16)) AS locale_id,
						CAST(? AS VARCHAR(63)) AS name
						FROM RDB\$DATABASE'

					params[current_translation * 3] = product_option_value_id_bin
					params[current_translation * 3 + 1] = translation.locale_id_bin
					params[current_translation * 3 + 2] = translation.name

					current_translation++
				}
			}
		}

		tx.execute('INSERT INTO product_option_value_translations (product_option_value_id, locale_id, name)
			${get_merge_source(src)}',
			...params)!
	}
}

fn model_product_option_update(mut tx firebird.Transaction, product_option_id_bin []u8, ph ProductOptionUpdateRequestHygienised) ! {
	if title := ph.title {
		tx.execute('UPDATE product_option SET title = ? WHERE id = ?', title, product_option_id_bin)!
	}

	if translations := ph.translations {
		mut src := []string{len: translations.len}
		mut params := []firebird.Value{len: translations.len * 3 + 1, init: firebird.Null{}}
		for i := 0; i < translations.len; i++ {
			src[i] = 'SELECT
				CAST(? AS BINARY(16)) AS product_option_id,
				CAST(? AS VARCHAR(63)) AS title,
				CAST(? AS BINARY(16)) AS locale_id
				FROM RDB\$DATABASE'
			params[i * 3] = product_option_id_bin
			params[i * 3 + 1] = translations[i].title
			params[i * 3 + 2] = translations[i].locale_id_bin
		}
		params[translations.len * 3] = product_option_id_bin

		tx.execute('MERGE INTO product_option_translations t
			USING (${get_merge_source(src)}) s (product_option_id, title, locale_id)
			ON t.product_option_id = s.product_option_id AND t.locale_id = s.locale_id
			WHEN NOT MATCHED THEN
				INSERT (product_option_id, locale_id, title)
				VALUES (s.product_option_id, s.locale_id, s.title)
			WHEN NOT MATCHED BY SOURCE
				AND t.product_option_id = ?
			THEN DELETE',
			...params)!
	}
}

fn model_product_option_delete(mut tx firebird.Transaction, id_bin []u8) ! {
	tx.execute('DELETE FROM product_option WHERE id = ?', id_bin)!
}

struct ProductOptionValueProductVariant {
	option_value_id     string
	option_value_id_bin []u8
	variant_id          string
	variant_id_bin      []u8
}

fn model_product_option_value_product_variant_retrieve(mut tx firebird.Transaction, option_value_ids_bin [][]u8) ![]ProductOptionValueProductVariant {
	data := tx.execute('SELECT option_value_id, variant_id
		FROM product_option_value_product_variant
		WHERE option_value_id IN (${get_placeholders(option_value_ids_bin)})',
		...workaround_24757(option_value_ids_bin))!

	rows := data.rows()

	mut product_option_value_product_variants := []ProductOptionValueProductVariant{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()

		option_value_id_bin, _ := v[0].get_array_u8()!
		variant_id_bin, _ := v[1].get_array_u8()!

		option_value_id := id_bin_to_string(option_value_id_bin)!
		variant_id := id_bin_to_string(variant_id_bin)!

		product_option_value_product_variants[i] = ProductOptionValueProductVariant{
			option_value_id:     option_value_id
			option_value_id_bin: option_value_id_bin
			variant_id:          variant_id
			variant_id_bin:      variant_id_bin
		}
	}
	return product_option_value_product_variants
}

fn model_product_option_value_product_variant_update(mut tx firebird.Transaction, variant_id_bin []u8, option_value_ids_bin [][]u8) ! {
	tx.execute('DELETE FROM product_option_value_product_variant WHERE variant_id = ?',
		variant_id_bin)!

	mut src := []string{len: option_value_ids_bin.len}
	mut params := []firebird.Value{len: option_value_ids_bin.len * 2, init: firebird.Null{}}
	for i := 0; i < variant_id_bin.len; i++ {
		src[i] = 'SELECT
			CAST(? AS BINARY(16)) AS option_value_id,
			CAST(? AS BINARY(16)) AS variant_id,
			FROM RDB\$DATABASE'
		params[i * 2] = option_value_ids_bin[i]
		params[i * 2 + 1] = variant_id_bin
	}

	tx.execute('INSERT INTO product_option_value_product_variant (option_value_id, variant_id)
		${get_merge_source(src)}',
		...params)!
}
