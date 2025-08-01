module peony

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
	data := tx.execute('SELECT id, option_id, variant_id FROM product_option_value
	WHERE option_id IN (${get_n_placeholders(i32(option_ids_bin.len))})',
		...workaround_24757(option_ids_bin))!

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
		WHERE product_option_id IN (${get_n_placeholders(i32(option_ids_bin.len))})',
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
			WHERE product_id IN (${get_n_placeholders(i32(ids_bin.len))})',
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

// does not delete rows when a product_option exists in product_option_value.
// to delete a product_option first remove it from all variants.
// ideally: send an error to the client when a product_option that should be deleted is in use.
fn (mut app App) do_delete_product_options(mut tx firebird.Transaction, product_id_bin []u8) ! {
	tx.execute('DELETE FROM product_option po
		WHERE product_id = ? AND NOT EXISTS (
			SELECT 1 
			FROM product_option_value pov
			WHERE pov.option_id = po.id
		)',
		product_id_bin)!
}

fn model_product_option_create(mut tx firebird.Transaction, id_bin []u8, product_id_bin []u8) ! {
	tx.execute('INSERT INTO product_option (id, product_id) VALUES(?, ?)', id_bin, product_id_bin)!
}

fn model_product_option_update(mut tx firebird.Transaction, id_bin []u8, p ProductOptionRequest) ! {
	mut src := []string{len: p.translations.len}
	mut params := []firebird.Value{len: p.translations.len * 3 + 1, init: firebird.Value(firebird.Null{})}
	for i := 0; i < p.translations.len; i++ {
		src[i] = 'SELECT
			CAST(? AS BINARY(16)) AS product_option_id,
			CAST(? AS VARCHAR(63)) AS title,
			CAST(? AS BINARY(16)) AS locale_id
			FROM RDB\$DATABASE'
		params[i * 3] = id_bin
		params[i * 3 + 1] = p.translations[i].title
		params[i * 3 + 2] = p.translations[i].locale_id
	}
	params[p.translations.len * 3] = id_bin

	mut query := 'MERGE INTO product_option_translations t
		USING (${src.join('\nUNION ALL\n')}) s (product_option_id, title, locale_id)
		ON t.product_option_id = s.product_option_id AND t.locale_id = s.locale_id
		WHEN NOT MATCHED THEN
			INSERT (product_option_id, locale_id, title)
			VALUES (s.product_option_id, s.locale_id, s.title)
		WHEN NOT MATCHED BY SOURCE
			AND t.product_option_id = ?
			AND NOT EXISTS (
				SELECT 1
				FROM product_option_value pov
				WHERE pov.option_id = t.product_option_id
			)
		THEN DELETE'

	tx.execute(query, ...params)!
}

// used when creating a new product_option
// each product_variant must have one product_option_value for each existing product_option
// this function creates a product_option_value for each existing variant
fn model_product_option_value_create_default(mut tx firebird.Transaction, product_option_id_bin []u8, product_option_value_ids_bin [][]u8, variant_ids_bin [][]u8) ! {
	// first create product_option_value
	mut src := []string{len: product_option_value_ids_bin.len}
	mut params := []firebird.Value{len: product_option_value_ids_bin.len * 3, init: firebird.Value(firebird.Null{})}
	for i := 0; i < product_option_value_ids_bin.len; i++ {
		src[i] = 'SELECT
		CAST(? AS BINARY(16)) AS id,
		CAST(? AS BINARY(16)) AS option_id,
		CAST(? AS BINARY(16)) AS variant_id
		FROM RDB\$DATABASE'
		params[i * 3] = product_option_value_ids_bin[i]
		params[i * 3 + 1] = product_option_id_bin
		params[i * 3 + 2] = variant_ids_bin[i]
	}

	tx.execute('MERGE INTO product_option_value t
		USING (${get_merge_source(src)}) s (id, option_id, variant_id)
		ON t.id = s.id
		WHEN NOT MATCHED THEN
			INSERT (id, option_id, variant_id)
			VALUES (s.id, s.option_id, s.variant_id)',
		...params)!

	// then insert product_option_value_translations
	params = []firebird.Value{len: product_option_value_ids_bin.len * 2, init: firebird.Value(firebird.Null{})}
	for i := 0; i < product_option_value_ids_bin.len; i++ {
		src[i] = 'SELECT
			CAST(? AS BINARY(16)) AS product_option_value_id,
			(SELECT default_locale_id FROM STORE) AS locale_id,
			CAST(? AS VARCHAR(63)) AS name
			FROM RDB\$DATABASE'
		params[i * 2] = product_option_value_ids_bin[i]
		params[i * 2 + 1] = 'default_value'
	}

	tx.execute('MERGE INTO product_option_value_translations t
		USING (${get_merge_source(src)}) s (product_option_value_id, locale_id, name)
		ON t.product_option_value_id = s.product_option_value_id
		WHEN NOT MATCHED THEN
			INSERT (product_option_value_id, locale_id, name)
			VALUES (s.product_option_value_id, s.locale_id, s.name)',
		...params)!
}

// used when cereating a new product_variant
// each product_variant must have one product_option_value for each existing product_option
// this function creates a product_option_value for each existing product_option
// TODO unneeded: enforce the user to provide the values
// fn model_product_option_value_create_default(mut tx firebird.Transaction, product_option_value_id_bin []u8, product_option_ids_bin [][]u8, variant_id_bin []u8) ! {
// }
