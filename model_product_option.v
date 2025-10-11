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

fn model_product_option_value_translations_retrieve(mut tx firebird.Transaction, product_option_value_ids_bin [][]u8) ![]ProductOptionValueTranslation {
	data := tx.execute('SELECT product_option_value_id, locale_id, name
	FROM product_option_value_translations
	WHERE product_option_value_id IN (${get_placeholders(product_option_value_ids_bin)})',
		...workaround_24757(product_option_value_ids_bin))!

	rows := data.rows()

	mut translations := []ProductOptionValueTranslation{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()

		product_option_value_id_bin, _ := v[0].get_array_u8()!
		locale_id_bin, _ := v[1].get_array_u8()!
		name, _ := v[2].get_string()!

		product_option_value_id := id_bin_to_string(product_option_value_id_bin)!
		locale_id := id_bin_to_string(locale_id_bin)!

		translations[i] = ProductOptionValueTranslation{
			product_option_value_id:     product_option_value_id
			product_option_value_id_bin: product_option_value_id_bin
			locale_id:                   locale_id
			locale_id_bin:               locale_id_bin
			name:                        name
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

fn model_product_option_values_retrieve(mut tx firebird.Transaction, locale_id_bin []u8, product_option_ids_bin [][]u8) ![]ProductOptionValue {
	mut params := []firebird.Value{}

	params = arrays.concat(params, ...workaround_24757(product_option_ids_bin))

	if locale_id_bin.len > 0 {
		params = arrays.concat(params, locale_id_bin, locale_id_bin)
	} else {
		params = arrays.concat(params, firebird.Null{}, firebird.Null{})
	}

	params = arrays.concat(params, ...workaround_24757(product_option_ids_bin))

	data := tx.execute('SELECT
			pov.id,
			pov.option_id,
			COALESCE(povt_requested.name, povt_default.name) AS name,
		FROM product_option_value pov,
		LEFT JOIN product_option_value_translations povt_default
			ON povt_default.product_option_value_id = pov.id
			AND povt_default.locale_id = (SELECT default_locale_id FROM store)
		LEFT JOIN product_option_value_translations povt_requested
			ON CAST(? AS BINARY(16)) IS NOT NULL
			AND povt_requested.product_option_value_id = pov.id
			AND povt_requested.locale_id = ?
		WHERE pov.option_id IN (${get_placeholders(product_option_ids_bin)})',
		...params)!

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

fn model_product_option_value_translations_update(mut tx firebird.Transaction, product_option_value_id_bin [][]u8, ph []ProductOptionValueTranslationRequestHygienised) ! {
	tx.execute('DELETE FROM product_option_value_translations WHERE product_option_value_id = ?',
		product_option_value_id_bin)!

	mut src := []string{len: ph.len}
	mut params := []firebird.Value{len: ph.len * 3, init: firebird.Value(firebird.Null{})}
	for i := 0; i < ph.len; i++ {
		src[i] = 'SELECT
				CAST(? AS BINARY(16)) AS product_option_value_id,
				CAST(? AS BINARY(16)) AS locale_id,
				CAST(? AS VARCHAR(63)) AS name
				FROM RDB\$DATABASE'
		params[i * 3] = product_option_value_id_bin
		params[i * 3 + 1] = ph[i].locale_id_bin
		params[i * 3 + 2] = ph[i].name
	}

	tx.execute('INSERT INTO product_option_value_translations (product_option_value_id, locale_id)
		${get_merge_source(src)}',
		...params)!
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

fn model_product_option_translations_retrieve(mut tx firebird.Transaction, product_option_ids_bin [][]u8) ![]ProductOptionTranslation {
	data := tx.execute('SELECT product_option_id, locale_id, title
		FROM product_option_translations
		WHERE product_option_id IN (${get_placeholders(product_option_ids_bin)})',
		...workaround_24757(product_option_ids_bin))!

	rows := data.rows()

	mut translations := []ProductOptionTranslation{}
	for i := 0; i < rows.len; i++ {
		translation := parse_product_option_translation(rows[i].values())!
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

fn model_product_options_retrieve_by_product_ids(mut tx firebird.Transaction, product_ids_bin [][]u8) ![]ProductOption {
	mut data := tx.execute('SELECT id, product_id FROM product_option
			WHERE product_id IN (${get_placeholders(product_ids_bin)})',
		...workaround_24757(product_ids_bin))!

	rows := data.rows()

	if rows.len == 0 {
		return []ProductOption{}
	}

	mut options := []ProductOption{len: rows.len}
	mut option_ids_bin := [][]u8{len: rows.len}
	for i := 0; i < rows.len; i++ {
		options[i] = parse_product_option(rows[i].values())!
		option_ids_bin[i] = options[i].id_bin
	}
	return options
}

// does not delete rows when a product_option exists in product_option_value.
// to delete a product_option first remove it from all variants.
// ideally: send an error to the client when a product_option that should be deleted is in use.
fn (mut app App) do_delete_product_options(mut tx firebird.Transaction, product_id_bin []u8) ! {
	tx.execute('DELETE FROM product_option po
		WHERE product_id = ? 
		AND NOT EXISTS (
			SELECT 1 
			FROM product_option_value pov
			WHERE pov.option_id = po.id
		)',
		product_id_bin)!
}

fn model_product_option_create(mut tx firebird.Transaction, id_bin []u8, product_id_bin []u8) ! {
	tx.execute('INSERT INTO product_option (id, product_id) VALUES(?, ?)', id_bin, product_id_bin)!
}

// note: does not protect from deleting default_locale_id translations.
fn model_product_option_translations_update(mut tx firebird.Transaction, id_bin []u8, ph []ProductOptionTranslationRequestHygienised) ! {
	mut src := []string{len: ph.len}
	mut params := []firebird.Value{len: ph.len * 3 + 1, init: firebird.Value(firebird.Null{})}
	for i := 0; i < ph.len; i++ {
		src[i] = 'SELECT
			CAST(? AS BINARY(16)) AS product_option_id,
			CAST(? AS VARCHAR(63)) AS title,
			CAST(? AS BINARY(16)) AS locale_id
			FROM RDB\$DATABASE'
		params[i * 3] = id_bin
		params[i * 3 + 1] = ph[i].title
		params[i * 3 + 2] = ph[i].locale_id_bin
	}
	params[ph.len * 3] = id_bin

	query := 'MERGE INTO product_option_translations t
		USING (${get_merge_source(src)}) s (product_option_id, title, locale_id)
		ON t.product_option_id = s.product_option_id AND t.locale_id = s.locale_id
		WHEN NOT MATCHED THEN
			INSERT (product_option_id, locale_id, title)
			VALUES (s.product_option_id, s.locale_id, s.title)
		WHEN NOT MATCHED BY SOURCE
			AND t.product_option_id = ?
		THEN DELETE'

	tx.execute(query, ...params)!
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

fn model_product_option_value_product_variant_update(mut tx firebird.Transaction, variant_id_bin []u8, money_amount_ids_bin [][]u8) ! {
	mut src := []string{len: money_amount_ids_bin.len}
	mut params := []firebird.Value{len: money_amount_ids_bin.len * 2, init: firebird.Value(firebird.Null{})}
	for i := 0; i < variant_id_bin.len; i++ {
		src[i] = 'SELECT
			CAST(? AS BINARY(16)) AS variant_id,
			CAST(? AS BINARY(16)) AS money_amount_id,
			FROM RDB\$DATABASE'
		params[i * 2] = variant_id_bin
		params[i * 2 + 1] = money_amount_ids_bin[i]
	}
	tx.execute('ISNERT INTO product_variant_money_amount (variant_id, money_amount_id)
		${get_merge_source(src)}',
		...params)!
}
