module record

import arrays
import einar_hjortdal.firebird

pub struct ProductOptionValueTranslation {
pub:
	option_value_id ID
	locale_id       ID
	name            string
}

pub fn (pov_t ProductOptionValueTranslation) locale_id() ID {
	return pov_t.locale_id
}

pub fn product_option_value_translations_retrieve(mut tx firebird.Transaction, product_option_value_ids []ID) ![]ProductOptionValueTranslation {
	data := tx.execute('SELECT product_option_value_id, locale_id, name
	FROM product_option_value_translations
	WHERE product_option_value_id IN (${get_placeholders(product_option_value_ids)})',
		...ids_bytes(product_option_value_ids))!

	rows := data.rows()

	mut translations := []ProductOptionValueTranslation{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()

		option_value_id_bin, _ := v[0].get_array_u8()!
		locale_id_bin, _ := v[1].get_array_u8()!
		name, _ := v[2].get_string()!

		option_value_id := id_from_bytes(option_value_id_bin)!
		locale_id := id_from_bytes(locale_id_bin)!

		translations[i] = ProductOptionValueTranslation{
			option_value_id: option_value_id
			locale_id:       locale_id
			name:            name
		}
	}
	return translations
}

pub struct ProductOptionValue {
pub:
	id         ID
	option_id  ID
	value_rank i32
	name       string
pub mut:
	translations []ProductOptionValueTranslation
}

// TODO fetch...
pub struct ProductOptionValueRetrieveParams {
pub:
	ids        ?[]ID
	option_ids ?[]ID
}

pub fn product_option_values_retrieve(mut tx firebird.Transaction, p ProductOptionValueRetrieveParams) ![]ProductOptionValue {
	if p.ids != none && p.option_ids != none {
		return error('Could not retrieve product_option_value: received both ids and option_ids')
	}

	if p.ids == none && p.option_ids == none {
		return []ProductOptionValue{}
	}

	mut query := 'SELECT id, option_id, value_rank, name FROM product_option_value'
	mut params := []firebird.Value{}
	if ids := p.ids {
		query = appendln(query, 'WHERE id IN (${get_placeholders(ids)})')
		params = ids_values(ids)
	}

	if option_ids := p.option_ids {
		query = appendln(query, 'WHERE option_id IN (${get_placeholders(option_ids)})')
		params = ids_values(option_ids)
	}

	query = appendln(query, 'ORDER BY value_rank')

	data := tx.execute(query, ...params)!
	rows := data.rows()

	mut product_option_values := []ProductOptionValue{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()

		id_bin, _ := v[0].get_array_u8()!
		option_id_bin, _ := v[1].get_array_u8()!
		value_rank, _ := v[2].get_i32()!
		name, _ := v[3].get_string()!

		id := id_from_bytes(id_bin)!
		option_id := id_from_bytes(option_id_bin)!

		product_option_values[i] = ProductOptionValue{
			id:         id
			option_id:  option_id
			value_rank: value_rank
			name:       name
		}
	}

	return product_option_values
}

pub struct ProductOptionValueUpdateParams {
pub:
	id         ID
	option_id  ID
	value_rank i32
	name       string
}

pub fn product_option_value_update(mut tx firebird.Transaction, p []ProductOptionValueUpdateParams) ! {
	mut src := []string{len: p.len}
	n_params := 4
	mut params := []firebird.Value{len: p.len * n_params, init: firebird.Null{}}
	mut option_ids_map := map[string]ID{}
	for i := 0; i < p.len; i++ {
		value := p[i]
		option_id := value.option_id
		src[i] = 'SELECT
			CAST(? AS BINARY(16)) AS id,
			CAST(? AS BINARY(16)) AS option_id,
			CAST(? AS INTEGER) AS value_rank,
			CAST(? AS VARCHAR(63)) AS name
			FROM RDB\$DATABASE'

		params[i * n_params + 0] = value.id.bytes()
		params[i * n_params + 1] = option_id.bytes()
		params[i * n_params + 2] = value.value_rank
		params[i * n_params + 3] = value.name

		option_ids_map[option_id.string()] = option_id
	}

	option_ids := option_ids_map.values()
	params = arrays.concat(params, ...ids_bytes(option_ids))

	query := 'MERGE INTO product_option_value t
		USING (${get_merge_source(src)}) s
		ON s.id = t.id
		WHEN MATCHED THEN UPDATE
			SET t.value_rank = s.value_rank, t.name = s.name
		WHEN NOT MATCHED THEN INSERT
			(id, option_id, value_rank, name)
			VALUES (s.id, s.option_id, s.value_rank, s.name)
		WHEN NOT MATCHED BY SOURCE AND t.option_id IN (${get_placeholders(option_ids)})
			THEN DELETE'

	tx.execute(query, ...params)!
}

pub fn product_option_value_delete(mut tx firebird.Transaction, product_option_value_id_bin []u8) ! {
	tx.execute('DELETE FROM product_option_value WHERE id = ?', product_option_value_id_bin)!
}

pub struct ProductOptionTranslation {
pub:
	product_option_id ID
	locale_id         ID
	title             string
}

pub fn (po_t ProductOptionTranslation) locale_id() ID {
	return po_t.locale_id
}

fn product_option_translations_retrieve(mut tx firebird.Transaction, product_option_ids_bin [][]u8) ![]ProductOptionTranslation {
	data := tx.execute('SELECT product_option_id, locale_id, title
		FROM product_option_translations
		WHERE product_option_id IN (${get_placeholders(product_option_ids_bin)})',
		...product_option_ids_bin)!

	rows := data.rows()

	mut translations := []ProductOptionTranslation{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()

		product_option_id_bin, _ := v[0].get_array_u8()!
		locale_id_bin, _ := v[1].get_array_u8()!
		title, _ := v[2].get_string()!

		product_option_id := id_from_bytes(product_option_id_bin)!
		locale_id := id_from_bytes(locale_id_bin)!

		translations[i] = ProductOptionTranslation{
			product_option_id: product_option_id
			locale_id:         locale_id
			title:             title
		}
	}

	return translations
}

pub struct ProductOption {
pub:
	id          ID
	product_id  ID
	option_rank i32
	title       string
pub mut:
	values       []ProductOptionValue
	translations []ProductOptionTranslation
}

fn (p ProductOption) id() ID {
	return p.id
}

pub fn product_option_retrieve(mut tx firebird.Transaction, product_ids []ID) ![]ProductOption {
	query := 'SELECT id, product_id, option_rank, title FROM product_option
		WHERE product_id IN (${get_placeholders(product_ids)})
		ORDER BY option_rank'

	params := ids_values(product_ids)

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

		id := id_from_bytes(id_bin)!
		product_id := id_from_bytes(product_id_bin)!

		options[i] = ProductOption{
			id:          id
			product_id:  product_id
			option_rank: option_rank
			title:       title
		}
	}
	return options
}

// TODO validate before running operation
pub struct ProductOptionCreateParams {
pub:
	id          ID
	product_id  ID
	option_rank i32
	title       string
}

// used to create new product options during product creation
pub fn product_option_create(mut tx firebird.Transaction, p []ProductOptionCreateParams) ! {
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

		params[i * 4] = option.id.bytes()
		params[i * 4 + 1] = option.product_id.bytes()
		params[i * 4 + 2] = option.option_rank
		params[i * 4 + 3] = option.title
	}

	query := 'INSERT INTO product_option (id, product_id, option_rank, title) ${get_merge_source(src)}'
	tx.execute(query, ...params)!
}

// TODO validate before running operation
pub struct ProductOptionTranslationParams {
pub:
	product_option_id ID
	locale_id         ID
	title             string
}

pub fn product_option_translations_create(mut tx firebird.Transaction, p []ProductOptionTranslationParams) ! {
	mut src := []string{len: p.len}
	mut params := []firebird.Value{len: p.len * 3, init: firebird.Null{}}
	for i := 0; i < p.len; i++ {
		translation := p[i]
		if translation.product_option_id.is_zero() {
			return error('Invalid product_option_id: ID.is_zero()')
		}

		if translation.locale_id.is_zero() {
			return error('Invalid locale_id: ID.is_zero()')
		}

		src[i] = 'SELECT
			CAST(? AS BINARY(16)) AS product_option_id,
			CAST(? AS BINARY(16)) AS locale_id,
			CAST(? AS VARCHAR(63)) AS title
			FROM RDB\$DATABASE'

		params[i * 3] = translation.product_option_id.bytes()
		params[i * 3 + 1] = translation.locale_id.bytes()
		params[i * 3 + 2] = translation.title
	}

	query := 'INSERT INTO product_option_translations
		(product_option_id, locale_id, title)
		${get_merge_source(src)}'
	tx.execute(query, ...params)!
}

// TODO validate before running operation
pub struct ProductOptionValueCreateParams {
pub:
	id         ID
	option_id  ID
	value_rank i32
	name       string
}

pub fn product_option_value_create(mut tx firebird.Transaction, p []ProductOptionValueCreateParams) ! {
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

		params[i * 4] = value.id.bytes()
		params[i * 4 + 1] = value.option_id.bytes()
		params[i * 4 + 2] = value.value_rank
		params[i * 4 + 3] = value.name
	}

	query := 'INSERT INTO product_option_value (id, option_id, value_rank, name) ${get_merge_source(src)}'
	tx.execute(query, ...params)!
}

// TODO validate before running operation
pub struct ProductOptionValueTranslationParams {
pub:
	product_option_value_id ID
	locale_id               ID
	name                    string
}

pub fn product_option_value_translations_create(mut tx firebird.Transaction, p []ProductOptionValueTranslationParams) ! {
	mut src := []string{len: p.len}
	mut params := []firebird.Value{len: p.len * 3, init: firebird.Null{}}
	for i := 0; i < p.len; i++ {
		translation := p[i]
		src[i] = 'SELECT
			CAST(? AS BINARY(16)) AS product_option_id,
			CAST(? AS BINARY(16)) AS locale_id,
			CAST(? AS VARCHAR(63)) AS title
			FROM RDB\$DATABASE'

		params[i * 3] = translation.product_option_value_id.bytes()
		params[i * 3 + 1] = translation.locale_id.bytes()
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
pub struct ProductOptionValueTranslationUpdateParams {
pub:
	product_option_value_ids []ID
	translations             []ProductOptionValueTranslationParams
}

pub fn product_option_value_translations_update(mut tx firebird.Transaction, p ProductOptionValueTranslationUpdateParams) ! {
	mut src := []string{len: p.translations.len}
	n_params := 3
	mut params := []firebird.Value{len: p.translations.len * n_params, init: firebird.Null{}}
	mut product_option_value_ids_map := map[string][]u8{}
	for i := 0; i < p.translations.len; i++ {
		translation := p.translations[i]
		product_option_value_id := translation.product_option_value_id
		src[i] = 'SELECT
			CAST(? AS BINARY(16)) AS product_option_value_id,
			CAST(? AS BINARY(16)) AS locale_id,
			CAST(? AS VARCHAR(63)) AS name
			FROM RDB\$DATABASE'

		params[i * n_params + 0] = product_option_value_id.bytes()
		params[i * n_params + 1] = translation.locale_id.bytes()
		params[i * n_params + 2] = translation.name

		product_option_value_ids_map[product_option_value_id.string()] =
			product_option_value_id.bytes()
	}

	params = arrays.concat(params, ...ids_bytes(p.product_option_value_ids))

	query := 'MERGE INTO product_option_value_ids_map
		USING (${get_merge_source(src)}) s
		ON s.product_option_value_id = t.product_option_value_id AND s.locale_id = t.locale_id
		WHEN MATCHED THEN UPDATE
			SET t.name = s.name
		WHEN NOT MATCHED THEN INSERT
			(product_option_value_id, locale_id, name)
			VALUES (s.product_option_value_id, s.locale_id, s.name)
		WHEN NOT MATCHED BY SOURCE 
			AND t.product_option_value_ids_bin IN (${get_placeholders(p.product_option_value_ids)})
			THEN DELETE'

	tx.execute(query, ...params)!
}

pub struct ProductOptionUpdateParams {
pub:
	id          ID
	product_id  ID
	option_rank i32
	title       string
}

pub fn product_option_update(mut tx firebird.Transaction, p []ProductOptionUpdateParams) ! {
	mut src := []string{len: p.len}
	n_params := 4
	mut params := []firebird.Value{len: p.len * n_params, init: firebird.Null{}}

	// deduplicate product ids
	mut product_ids_map := map[string]ID{}

	for i := 0; i < p.len; i++ {
		option := p[i]
		if option.id.is_zero() {
			return error('option id is invalid: ID.is_zero()')
		}

		if option.product_id.is_zero() {
			return error('product_id is invalid: ID.is_zero()')
		}

		src[i] = 'SELECT
			CAST(? AS BINARY(16)) AS id,
			CAST(? AS BINARY(16)) AS product_id,
			CAST(? AS INTEGER) AS option_rank,
			CAST(? AS VARCHAR(63)) AS title
			FROM RDB\$DATABASE'

		params[n_params * i + 0] = option.id.bytes()
		params[n_params * i + 1] = option.product_id.bytes()
		params[n_params * i + 2] = option.option_rank
		params[n_params * i + 3] = option.title

		product_ids_map[option.product_id.string()] = option.product_id
	}

	product_ids := product_ids_map.values()

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
			AND t.product_id IN (${get_placeholders(product_ids)})
			THEN DELETE'

	params = arrays.concat(params, ...ids_bytes(product_ids))

	tx.execute(query, ...params)!
}

// ProductOptionTranslationUpdateParams
// - product_option_ids: IDs of all options being updated (ordered).
// - translations: flat list of ProductOptionTranslation rows to create or update.
//
// ## Behavior
// - For each id in product_option_ids: replace that option's translations with the provided translations.
// - If an option has no provided translations, delete all existing translations for that option.
pub struct ProductOptionTranslationUpdateParams {
pub:
	product_option_ids []ID
	translations       []ProductOptionTranslationParams
}

pub fn product_option_translations_update(mut tx firebird.Transaction, p ProductOptionTranslationUpdateParams) ! {
	mut src := []string{len: p.translations.len}
	n_params := 3
	mut params := []firebird.Value{len: p.translations.len * n_params + 1, init: firebird.Null{}}

	for i := 0; i < p.product_option_ids.len; i++ {
		product_option_id := p.product_option_ids[i]
		if product_option_id.is_zero() {
			return error('product_option_id is invalid: ID.is_zero()')
		}
	}
	// TODO validate translations...

	for i := 0; i < p.translations.len; i++ {
		translation := p.translations[i]
		src[i] = 'SELECT
					CAST(? AS BINARY(16)) AS product_option_id,
					CAST(? AS BINARY(16)) AS locale_id,
					CAST(? AS VARCHAR(63)) AS title
					FROM RDB\$DATABASE'
		params[i * n_params + 0] = translation.product_option_id.bytes()
		params[i * n_params + 1] = translation.locale_id.bytes()
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
			AND t.product_option_id IN (${get_placeholders(p.product_option_ids)})
			THEN DELETE'

	params = arrays.concat(params, ...ids_bytes(p.product_option_ids))

	tx.execute(query, ...params)!
}

pub fn product_option_delete(mut tx firebird.Transaction, id_bin []u8) ! {
	tx.execute('DELETE FROM product_option WHERE id = ?', id_bin)!
}

pub struct ProductOptionValueVariant {
pub:
	option_value_id ID
	variant_id      ID
}

pub struct ProductOptionValueVariantRetrieveParams {
pub:
	option_value_ids ?[]ID
	variant_ids      ?[]ID
}

pub fn product_option_value_variant_retrieve(mut tx firebird.Transaction, p ProductOptionValueVariantRetrieveParams) ![]ProductOptionValueVariant {
	if p.option_value_ids == none && p.variant_ids == none {
		return error('Cannot retrieve product_option_value_variant: neither option_value_ids nor variant_ids provided')
	}

	if p.option_value_ids != none && p.variant_ids != none {
		return error('Cannot retrieve product_option_value_variant: both option_value_ids and variant_ids provided')
	}

	mut query := 'SELECT option_value_id, variant_id FROM product_option_value_variant'
	mut params := []firebird.Value{}
	if option_value_ids := p.option_value_ids {
		query = '${query} WHERE option_value_id IN (${get_placeholders(option_value_ids)})'
		params = ids_values(option_value_ids)
	}

	if variant_ids := p.variant_ids {
		query = '${query} WHERE variant_id IN (${get_placeholders(variant_ids)})'
		params = ids_values(variant_ids)
	}

	data := tx.execute(query, ...params)!

	rows := data.rows()

	mut product_option_value_variants := []ProductOptionValueVariant{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()

		option_value_id_bin, _ := v[0].get_array_u8()!
		variant_id_bin, _ := v[1].get_array_u8()!

		option_value_id := id_from_bytes(option_value_id_bin)!
		variant_id := id_from_bytes(variant_id_bin)!

		product_option_value_variants[i] = ProductOptionValueVariant{
			option_value_id: option_value_id
			variant_id:      variant_id
		}
	}
	return product_option_value_variants
}

pub struct ProductOptionValueVariantUpdateParams {
pub:
	variant_ids []ID
	relations   []ProductOptionValueVariant
}

// TODO validate params
pub fn product_option_value_variant_update(mut tx firebird.Transaction, p ProductOptionValueVariantUpdateParams) ! {
	mut src := []string{len: p.relations.len}
	n_params := 2
	mut params := []firebird.Value{len: p.relations.len * n_params, init: firebird.Null{}}

	for i := 0; i < p.relations.len; i++ {
		r := p.relations[i]
		src[i] = 'SELECT
			CAST(? AS BINARY(16)) AS option_value_id,
			CAST(? AS BINARY(16)) AS variant_id
			FROM RDB\$DATABASE'

		params[i * n_params + 0] = r.option_value_id.bytes()
		params[i * n_params + 1] = r.variant_id.bytes()
	}

	query := 'MERGE INTO product_option_value_variant t
		USING (${get_merge_source(src)}) s
		ON t.option_value_id = s.option_value_id AND t.variant_id = s.variant_id
		WHEN NOT MATCHED THEN
			INSERT (option_value_id, variant_id)
			VALUES (s.option_value_id, s.variant_id)
		WHEN NOT MATCHED BY SOURCE AND t.variant_id IN (${get_placeholders(p.variant_ids)}) THEN
			DELETE'
	params = arrays.concat(params, ...ids_bytes(p.variant_ids))

	tx.execute(query, ...params)!
}

