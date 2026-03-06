module peony

import arrays
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
	value_rank    i32
	name          string
mut:
	translations []ProductOptionValueTranslation
}

fn model_product_option_values_retrieve(mut tx firebird.Transaction, product_option_ids []string, product_option_ids_bin [][]u8) ![]ProductOptionValue {
	if product_option_ids_bin.len == 0 {
		return []ProductOptionValue{}
	}

	query := 'SELECT id, option_id, value_rank, name FROM product_option_value
		WHERE option_id IN (${get_placeholders(product_option_ids_bin)})
		ORDER BY value_rank'
	params := workaround_24757(product_option_ids_bin)
	data := tx.execute(query, ...params)!
	rows := data.rows()

	mut product_option_values := []ProductOptionValue{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()

		id_bin, _ := v[0].get_array_u8()!
		option_id_bin, _ := v[1].get_array_u8()!
		value_rank, _ := v[2].get_i32()!
		name, _ := v[3].get_string()!

		id := id_bin_to_string(id_bin)!
		option_id := id_bin_to_string(option_id_bin)!

		product_option_values[i] = ProductOptionValue{
			id:            id
			id_bin:        id_bin
			option_id:     option_id
			option_id_bin: option_id_bin
			value_rank:    value_rank
			name:          name
		}
	}

	return product_option_values
}

struct ProductOptionValueUpdateParams {
	id            string
	id_bin        []u8
	option_id     string
	option_id_bin []u8
	value_rank    i32
	name          string
}

fn model_product_option_value_update(mut tx firebird.Transaction, p []ProductOptionValueUpdateParams) ! {
	mut src := []string{len: p.len}
	n_params := 4
	mut params := []firebird.Value{len: p.len * n_params, init: firebird.Null{}}
	mut option_ids_map := map[string][]u8{}
	for i := 0; i < p.len; i++ {
		value := p[i]
		src[i] = 'SELECT
			CAST(? AS BINARY(16)) AS id,
			CAST(? AS BINARY(16)) AS option_id,
			CAST(? AS INTEGER) AS value_rank,
			CAST(? AS VARCHAR(63)) AS name
			FROM RDB\$DATABASE'

		params[i * n_params + 0] = value.id_bin
		params[i * n_params + 1] = value.option_id_bin
		params[i * n_params + 2] = value.value_rank
		params[i * n_params + 3] = value.name

		option_ids_map[value.option_id] = value.option_id_bin
	}

	option_ids_bin := option_ids_map.values()
	params = arrays.concat(params, ...workaround_24757(option_ids_bin))

	query := 'MERGE INTO product_option_value t
		USING (${get_merge_source(src)}) s
		ON s.id = t.id
		WHEN MATCHED THEN UPDATE
			SET t.value_rank = s.value_rank, t.name = s.name
		WHEN NOT MATCHED THEN INSERT
			(id, option_id, value_rank, name)
			VALUES (s.id, s.option_id, s.value_rank, s.name)
		WHEN NOT MATCHED BY SOURCE AND t.option_id IN (${get_placeholders(option_ids_bin)})
			THEN DELETE'

	tx.execute(query, ...params)!
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
	option_rank    i32
	title          string
mut:
	values       []ProductOptionValue
	translations []ProductOptionTranslation
}

fn model_product_options_retrieve(mut tx firebird.Transaction, product_ids_bin [][]u8) ![]ProductOption {
	query := 'SELECT id, product_id, option_rank, title FROM product_option
		WHERE product_id IN (${get_placeholders(product_ids_bin)})
		ORDER BY option_rank'

	params := workaround_24757(product_ids_bin)

	mut data := tx.execute(query, ...params)!

	rows := data.rows()

	if rows.len == 0 {
		return []ProductOption{}
	}

	mut options := []ProductOption{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()

		id_bin, _ := v[0].get_array_u8()!
		product_id_bin, _ := v[1].get_array_u8()!
		option_rank, _ := v[2].get_i32()!
		title, _ := v[3].get_string()!

		id := id_bin_to_string(id_bin)!
		product_id := id_bin_to_string(product_id_bin)!

		options[i] = ProductOption{
			id:             id
			id_bin:         id_bin
			product_id:     product_id
			product_id_bin: product_id_bin
			option_rank:    option_rank
			title:          title
		}
	}
	return options
}

// TODO validate before running operation
struct ProductOptionCreateParams {
	id             string
	id_bin         []u8
	product_id     string
	product_id_bin []u8
	option_rank    i32
	title          string
}

// used to create new product options during product creation
fn model_product_option_create(mut tx firebird.Transaction, p []ProductOptionCreateParams) ! {
	mut src := []string{len: p.len}
	mut params := []firebird.Value{len: p.len * 4, init: firebird.Null{}}
	for i := 0; i < p.len; i++ {
		option := p[i]
		src[i] = 'SELECT
			CAST(? AS BINARY(16)) AS id,
			CAST(? AS BINARY(16)) AS product_id,
			CAST(? AS INTEGER) AS option_rank,
			CAST(? AS VARCHAR(63)) AS title
			FROM RDB\$DATABASE'

		params[i * 4] = option.id_bin
		params[i * 4 + 1] = option.product_id_bin
		params[i * 4 + 2] = option.option_rank
		params[i * 4 + 3] = option.title
	}

	query := 'INSERT INTO product_option (id, product_id, option_rank, title) ${get_merge_source(src)}'
	tx.execute(query, ...params)!
}

// TODO validate before running operation
struct ProductOptionTranslationParams {
	product_option_id     string
	product_option_id_bin []u8
	locale_id             string
	locale_id_bin         []u8
	title                 string
}

fn model_product_option_translations_create(mut tx firebird.Transaction, p []ProductOptionTranslationParams) ! {
	mut src := []string{len: p.len}
	mut params := []firebird.Value{len: p.len * 3, init: firebird.Null{}}
	for i := 0; i < p.len; i++ {
		translation := p[i]
		src[i] = 'SELECT
			CAST(? AS BINARY(16)) AS product_option_id,
			CAST(? AS BINARY(16)) AS locale_id,
			CAST(? AS VARCHAR(63)) AS title
			FROM RDB\$DATABASE'

		params[i * 3] = translation.product_option_id_bin
		params[i * 3 + 1] = translation.locale_id_bin
		params[i * 3 + 2] = translation.title
	}

	query := 'INSERT INTO product_option_translations
		(product_option_id, locale_id, title)
		${get_merge_source(src)}'
	tx.execute(query, ...params)!
}

// TODO validate before running operation
struct ProductOptionValueCreateParams {
	id            string
	id_bin        []u8
	option_id     string
	option_id_bin []u8
	value_rank    i32
	name          string
}

fn model_product_option_value_create(mut tx firebird.Transaction, p []ProductOptionValueCreateParams) ! {
	mut src := []string{len: p.len}
	mut params := []firebird.Value{len: p.len * 4, init: firebird.Null{}}
	for i := 0; i < p.len; i++ {
		value := p[i]
		src[i] = 'SELECT
			CAST(? AS BINARY(16)) AS id,
			CAST(? AS BINARY(16)) AS option_id,
			CAST(? AS INTEGER) AS value_rank,
			CAST(? AS VARCHAR(63)) AS name
			FROM RDB\$DATABASE'

		params[i * 4] = value.id_bin
		params[i * 4 + 1] = value.option_id_bin
		params[i * 4 + 2] = value.value_rank
		params[i * 4 + 3] = value.name
	}

	query := 'INSERT INTO product_option_value (id, option_id, value_rank, name) ${get_merge_source(src)}'
	tx.execute(query, ...params)!
}

// TODO validate before running operation
struct ProductOptionValueTranslationParams {
	product_option_value_id     string
	product_option_value_id_bin []u8
	locale_id                   string
	locale_id_bin               []u8
	name                        string
}

fn model_product_option_value_translations_create(mut tx firebird.Transaction, p []ProductOptionValueTranslationParams) ! {
	mut src := []string{len: p.len}
	mut params := []firebird.Value{len: p.len * 3, init: firebird.Null{}}
	for i := 0; i < p.len; i++ {
		translation := p[i]
		src[i] = 'SELECT
			CAST(? AS BINARY(16)) AS product_option_id,
			CAST(? AS BINARY(16)) AS locale_id,
			CAST(? AS VARCHAR(63)) AS title
			FROM RDB\$DATABASE'

		params[i * 3] = translation.product_option_value_id
		params[i * 3 + 1] = translation.locale_id_bin
		params[i * 3 + 2] = translation.name
	}

	query := 'INSERT INTO product_option_value_translations
		(product_option_value_id, locale_id, title)
		${get_merge_source(src)}'
	tx.execute(query, ...params)!
}

// ProductOptionValueTranslationUpdateParams
// - product_option_value_id: ID of the option value being updated.
// - product_option_value_id_bin: binary ID ([]u8, 16 bytes).
// - translations: list of ProductOptionValueTranslationParams to create or update.
//
// ## Behavior
// - Replace the translations for the given product_option_value_id with the provided list.
// - If an option value has no provided translations, delete all existing translations for that option value.
struct ProductOptionValueTranslationUpdateParams {
	product_option_value_ids     []string
	product_option_value_ids_bin [][]u8
	translations                 []ProductOptionValueTranslationParams
}

fn model_product_option_value_translations_update(mut tx firebird.Transaction, p ProductOptionValueTranslationUpdateParams) ! {
	mut src := []string{len: p.translations.len}
	n_params := 3
	mut params := []firebird.Value{len: p.translations.len * n_params, init: firebird.Null{}}
	mut product_option_value_ids_map := map[string][]u8{}
	for i := 0; i < p.translations.len; i++ {
		translation := p.translations[i]
		src[i] = 'SELECT
			CAST(? AS BINARY(16)) AS product_option_value_id,
			CAST(? AS BINARY(16)) AS locale_id,
			CAST(? AS VARCHAR(63)) AS name
			FROM RDB\$DATABASE'

		params[i * n_params + 0] = translation.product_option_value_id_bin
		params[i * n_params + 1] = translation.locale_id_bin
		params[i * n_params + 2] = translation.name

		product_option_value_ids_map[translation.product_option_value_id] = translation.product_option_value_id_bin
	}

	params = arrays.concat(params, ...workaround_24757(p.product_option_value_ids_bin))

	query := 'MERGE INTO product_option_value_ids_map
		USING (${get_merge_source(src)}) s
		ON s.product_option_value_id = t.product_option_value_id AND s.locale_id = t.locale_id
		WHEN MATCHED THEN UPDATE
			SET t.name = s.name
		WHEN NOT MATCHED THEN INSERT
			(product_option_value_id, locale_id, name)
			VALUES (s.product_option_value_id, s.locale_id, s.name)
		WHEN NOT MATCHED BY SOURCE 
			AND t.product_option_value_ids_bin IN (${get_placeholders(p.product_option_value_ids_bin)})
			THEN DELETE'

	tx.execute(query, ...params)!
}

struct ProductOptionUpdateParams {
	id             string
	id_bin         []u8
	product_id     string
	product_id_bin []u8
	option_rank    i32
	title          string
}

fn model_product_option_update(mut tx firebird.Transaction, p []ProductOptionUpdateParams) ! {
	mut src := []string{len: p.len}
	n_params := 4
	mut params := []firebird.Value{len: p.len * n_params, init: firebird.Null{}}

	// deduplicate product ids
	mut product_ids := map[string][]u8{}

	for i := 0; i < p.len; i++ {
		option := p[i]
		if option.id == '' {
			return error('product_option id is invalid: ${option.id}')
		}

		if option.id_bin.len == 0 {
			return error('product_option id_bin is invalid: ${option.id_bin}')
		}

		if option.product_id == '' {
			return error('product_option product_id is invalid: ${option.product_id}')
		}

		if option.product_id_bin.len == 0 {
			return error('product_option product_id_bin is invalid: ${option.product_id_bin}')
		}

		src[i] = 'SELECT
			CAST(? AS BINARY(16)) AS id,
			CAST(? AS BINARY(16)) AS product_id,
			CAST(? AS INTEGER) AS option_rank,
			CAST(? AS VARCHAR(63)) AS title
			FROM RDB\$DATABASE'

		params[n_params * i + 0] = option.id_bin
		params[n_params * i + 1] = option.product_id_bin
		params[n_params * i + 2] = option.option_rank
		params[n_params * i + 3] = option.title

		product_ids[option.product_id] = option.product_id_bin
	}

	product_ids_bin := product_ids.values()

	query := 'MERGE INTO product_option t
		USING (${get_merge_source(src)}) s
		ON s.id = t.id
		WHEN MATCHED THEN UPDATE
			SET
				t.option_rank = s.option_rank,
				t.title = s.title
		WHEN NOT MATCHED THEN INSERT
			(id, product_id, option_rank, title)
			VALUES (s.id, s.product_id, s.option_rank, s.title)
		WHEN NOT MATCHED BY SOURCE
			AND t.product_id IN (${get_placeholders(product_ids_bin)})
			THEN DELETE'

	params = arrays.concat(params, ...workaround_24757(product_ids_bin))

	tx.execute(query, ...params)!
}

// ProductOptionTranslationUpdateParams
// - product_option_ids: IDs of all options being updated (ordered).
// - product_option_ids_bin: parallel []u8 (16 bytes each), matching product_option_ids by index.
// - translations: flat list of ProductOptionTranslation rows to create or update.
//
// ## Behavior
// - For each id in product_option_ids: replace that option's translations with the provided translations.
// - If an option has no provided translations, delete all existing translations for that option.
struct ProductOptionTranslationUpdateParams {
	product_option_ids     []string
	product_option_ids_bin [][]u8
	translations           []ProductOptionTranslationParams
}

fn model_product_option_translations_update(mut tx firebird.Transaction, p ProductOptionTranslationUpdateParams) ! {
	mut src := []string{len: p.translations.len}
	n_params := 3
	mut params := []firebird.Value{len: p.translations.len * n_params + 1, init: firebird.Null{}}
	for i := 0; i < p.translations.len; i++ {
		translation := p.translations[i]
		product_option_id_bin := translation.product_option_id_bin
		src[i] = 'SELECT
					CAST(? AS BINARY(16)) AS product_option_id,
					CAST(? AS BINARY(16)) AS locale_id,
					CAST(? AS VARCHAR(63)) AS title
					FROM RDB\$DATABASE'
		params[i * n_params + 0] = product_option_id_bin
		params[i * n_params + 1] = translation.locale_id_bin
		params[i * n_params + 2] = translation.title
	}

	query := 'MERGE INTO product_option_translations t
		USING (${get_merge_source(src)}) s
		ON t.product_option_id = s.product_option_id AND t.locale_id = s.locale_id
		WHEN MATCHED THEN UPDATE SET t.title = s.title
		WHEN NOT MATCHED THEN
			INSERT (product_option_id, locale_id, title)
			VALUES (s.product_option_id, s.locale_id, s.title)
		WHEN NOT MATCHED BY SOURCE
			AND t.product_option_id IN (${get_placeholders(p.product_option_ids_bin)})
			THEN DELETE'

	params = arrays.concat(params, ...workaround_24757(p.product_option_ids_bin))

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

struct ProductOptionValueProductVariantParams {
	variant_ids     []string
	variant_ids_bin [][]u8
	relations       []ProductOptionValueProductVariant
}

// TODO validate params
fn model_product_option_value_variant_update(mut tx firebird.Transaction, p ProductOptionValueProductVariantParams) ! {
	mut src := []string{len: p.relations.len}
	n_params := 2
	mut params := []firebird.Value{len: p.relations.len * n_params, init: firebird.Null{}}

	for i := 0; i < p.relations.len; i++ {
		r := p.relations[i]
		src[i] = 'SELECT
			CAST(? AS BINARY(16)) AS option_value_id,
			CAST(? AS BINARY(16)) AS variant_id
			FROM RDB\$DATABASE'

		params[i * n_params + 0] = r.option_value_id_bin
		params[i * n_params + 1] = r.variant_id_bin
	}

	query := 'MERGE INTO product_option_value_product_variant t
		USING (${get_merge_source(src)}) s
		ON t.option_value_id = s.option_value_id AND t.variant_id = s.variant_id
		WHEN NOT MATCHED THEN
			INSERT (option_value_id, variant_id)
			VALUES (s.option_value_id, s.variant_id)
		WHEN NOT MATCHED BY SOURCE AND t.variant_id IN (${get_placeholders(p.variant_ids_bin)}) THEN
			DELETE'
	params = arrays.concat(params, ...workaround_24757(p.variant_ids_bin))

	tx.execute(query, ...params)!
}
