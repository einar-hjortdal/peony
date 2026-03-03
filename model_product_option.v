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
	name          string
mut:
	translations []ProductOptionValueTranslation
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
struct ProductOptionTranslationCreateParams {
	product_option_id     string
	product_option_id_bin []u8
	locale_id             string
	locale_id_bin         []u8
	title                 string
}

fn model_product_option_translations_create(mut tx firebird.Transaction, p []ProductOptionTranslationCreateParams) ! {
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
	id_string     string
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
struct ProductOptionValueTranslationCreateParams {
	product_option_value_id     string
	product_option_value_id_bin []u8
	locale_id                   string
	locale_id_bin               []u8
	name                        string
}

fn model_product_option_value_translations_create(mut tx firebird.Transaction, p []ProductOptionValueTranslationCreateParams) ! {
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
		WHEN NOT MATCHED BY SOURCE AND t.product_id IN (${get_placeholders(product_ids_bin)})
			THEN DELETE'

	params = arrays.concat(params, ...workaround_24757(product_ids_bin))

	tx.execute(query, ...params)!
}

struct ProductOptionTranslationUpdateParams {
	product_option_id     string
	product_option_id_bin []u8
	locale_id             string
	locale_id_bin         []u8
	title                 string
}

fn model_product_option_translations_update(mut tx firebird.Transaction, p []ProductOptionTranslationUpdateParams) ! {
	mut src := []string{len: p.len}
	n_params := 3
	mut params := []firebird.Value{len: p.len * n_params + 1, init: firebird.Null{}}
	mut product_option_ids_map := map[string][]u8{}
	for i := 0; i < p.len; i++ {
		translation := p[i]
		product_option_id := translation.product_option_id
		product_option_id_bin := translation.product_option_id_bin
		src[i] = 'SELECT
					CAST(? AS BINARY(16)) AS product_option_id,
					CAST(? AS BINARY(16)) AS locale_id,
					CAST(? AS VARCHAR(63)) AS title
					FROM RDB\$DATABASE'
		params[i * n_params + 0] = product_option_id_bin
		params[i * n_params + 1] = translation.locale_id_bin
		params[i * n_params + 2] = translation.title

		product_option_ids_map[product_option_id] = product_option_id_bin
	}

	product_option_ids_bin := product_option_ids_map.values()

	query := 'MERGE INTO product_option_translations t
		USING (${get_merge_source(src)}) s
		ON t.product_option_id = s.product_option_id AND t.locale_id = s.locale_id
		WHEN MATCHED THEN UPDATE SET t.title = s.title
		WHEN NOT MATCHED THEN
			INSERT (product_option_id, locale_id, title)
			VALUES (s.product_option_id, s.locale_id, s.title)
		WHEN NOT MATCHED BY SOURCE
			AND t.product_option_id IN (${get_placeholders(product_option_ids_bin)})
		THEN DELETE'

	params = arrays.concat(params, ...workaround_24757(product_option_ids_bin))

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

// TODO check no empty variants id array
// TODO check no empty array in option_value_ids_bin
fn model_product_option_value_variants_update(mut tx firebird.Transaction, variant_ids_bin [][]u8, option_value_ids_bin [][][]u8) ! {
	if variant_ids_bin.len != option_value_ids_bin.len {
		return error('Number of variants does not match number of option_value arrays. got ${variant_ids_bin.len} variants and ${option_value_ids_bin.len} option_value arrays')
	}

	mut n_rows := 0
	for i := 0; i < option_value_ids_bin.len; i++ {
		n_option_values := option_value_ids_bin[i].len
		n_rows += n_option_values
	}

	if n_rows == 0 {
		return error('variants have no option_values, 0 rows to insert in product_option_value_product_variant')
	}

	// delete all relations first
	tx.execute('DELETE FROM product_option_value_product_variant WHERE variant_id IN (${get_placeholders(variant_ids_bin)})',
		...workaround_24757(variant_ids_bin))!

	// insert new relations
	mut rows_prepared := 0
	mut src := []string{len: n_rows}
	mut params := []firebird.Value{len: n_rows * 2, init: firebird.Null{}}
	for i := 0; i < variant_ids_bin.len; i++ {
		variant_id_bin := variant_ids_bin[i]
		value_ids_bin := option_value_ids_bin[i]
		for j := 0; j < value_ids_bin.len; j++ {
			value_id_bin := value_ids_bin[j]
			src[rows_prepared] = 'SELECT
				CAST(? AS BINARY(16)) AS option_value_id,
				CAST(? AS BINARY(16)) AS variant_id
				FROM RDB\$DATABASE'
			params[rows_prepared * 2] = value_id_bin
			params[rows_prepared * 2 + 1] = variant_id_bin

			rows_prepared++
		}
	}

	tx.execute('INSERT INTO product_option_value_product_variant (option_value_id, variant_id)
		${get_merge_source(src)}',
		...params)!
}

// updates one variant's option values
fn model_product_option_value_variant_update(mut tx firebird.Transaction, variant_id_bin []u8, value_ids_bin [][]u8) ! {
	variant_ids_bin := [variant_id_bin]
	option_value_ids_bin := [value_ids_bin]
	return model_product_option_value_variants_update(mut tx, variant_ids_bin, option_value_ids_bin)
}
