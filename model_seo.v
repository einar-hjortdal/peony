module peony

import arrays
import einar_hjortdal.firebird

struct ProductSEOTranslation {
	seo_id        string
	seo_id_bin    []u8
	locale_id     string
	locale_id_bin []u8
	title         firebird.NullString
	description   firebird.NullString
}

fn model_product_seo_translation_retrieve(mut tx firebird.Transaction, seo_ids_bin [][]u8) ![]ProductSEOTranslation {
	data := tx.execute('SELECT seo_id, locale_id, title, description
		FROM seo_translations
		WHERE seo_id IN (${get_placeholders(seo_ids_bin)})',
		...workaround_24757(seo_ids_bin))!

	rows := data.rows()

	mut seo_translations := []ProductSEOTranslation{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()

		seo_id_bin, _ := v[0].get_array_u8()!
		locale_id_bin, _ := v[1].get_array_u8()!
		title := v[2].get_null_string()!
		description := v[3].get_null_string()!

		seo_id := id_bin_to_string(seo_id_bin)!
		locale_id := id_bin_to_string(locale_id_bin)!

		seo_translations[i] = ProductSEOTranslation{
			seo_id:        seo_id
			seo_id_bin:    seo_id_bin
			locale_id:     locale_id
			locale_id_bin: locale_id_bin
			title:         title
			description:   description
		}
	}

	return seo_translations
}

struct ProductSEO {
	id             string
	id_bin         []u8
	product_id     string
	product_id_bin []u8
	title          firebird.NullString
	description    firebird.NullString
mut:
	translations []ProductSEOTranslation
}

fn model_product_seo_create_default(mut tx firebird.Transaction, seo_id_bin []u8, product_id_bin []u8) ! {
	tx.execute('INSERT INTO seo (id, product_id) VALUES (?, ?)', seo_id_bin, product_id_bin)!
}

fn model_product_seo_create(mut tx firebird.Transaction, seo_id_bin []u8, product_id_bin []u8, seo SEOCreateRequestHygienised) ! {
	mut columns := ['id', 'product_id']
	mut params := [firebird.Value(seo_id_bin), product_id_bin]

	if title := seo.title {
		columns = arrays.concat(columns, 'title')
		params = arrays.concat(params, title)
	}

	if description := seo.description {
		columns = arrays.concat(columns, 'description')
		params = arrays.concat(params, description)
	}

	tx.execute('INSERT INTO seo (${get_columns(columns)}) VALUES (${get_placeholders(columns)})',
		...params)!
}

fn model_product_seo_retrieve(mut tx firebird.Transaction, product_ids_bin [][]u8) ![]ProductSEO {
	data := tx.execute('SELECT id, product_id, title, description FROM seo
		WHERE product_id IN (${get_placeholders(product_ids_bin)})',
		...workaround_24757(product_ids_bin))!

	rows := data.rows()

	mut product_seo := []ProductSEO{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()

		id_bin, _ := v[0].get_array_u8()!
		product_id_bin, _ := v[1].get_array_u8()!
		title := v[2].get_null_string()!
		description := v[3].get_null_string()!

		id := id_bin_to_string(id_bin)!
		product_id := id_bin_to_string(product_id_bin)!

		product_seo[i] = ProductSEO{
			id:             id
			id_bin:         id_bin
			product_id:     product_id
			product_id_bin: product_id_bin
			title:          title
			description:    description
		}
	}

	return product_seo
}

// TODO think more on this struct definition, it still contains a Request struct and I don't like that
// TODO use function params instead to enforce them being provided.
// TODO rewrite
struct ProductSEOUpdateParams {
	product_id_bin          []u8
	seo_translation_ids_bin [][]u8
	seo_translations        []SEOTranslationUpdateRequestHygienised
}

// replaces all seo_translations related to product_id with new ones
// TODO rewrite: there will always be one seo databse row for each product
fn model_product_seo_update(mut tx firebird.Transaction, p ProductSEOUpdateParams) ! {
	tx.execute('DELETE FROM seo_translations WHERE product_id = ?', p.product_id_bin)!

	mut src := []string{len: p.seo_translations.len}
	mut params := []firebird.Value{len: p.seo_translations.len * 5, init: firebird.Value(firebird.Null{})}
	for i := 0; i < p.seo_translations.len; i++ {
		seo_translation := p.seo_translations[i]
		src[i] = 'SELECT
			CAST(? AS BINARY(16)) AS id,
			CAST(? AS BINARY(16)) AS locale_id,
			CAST(? AS BINARY(16)) AS product_id,
			CAST(? AS VARCHAR(63)) AS title,
			CAST(? AS VARCHAR(191)) AS description
			FROM RDB\$DATABASE'

		params[i * 5] = p.seo_translation_ids_bin[i]
		params[i * 5 + 1] = seo_translation.locale_id_bin
		params[i * 5 + 2] = p.product_id_bin

		if title := seo_translation.title {
			params[i * 5 + 3] = title
		} else {
			params[i * 5 + 3] = firebird.Null{}
		}

		if description := seo_translation.description {
			params[i * 5 + 4] = description
		} else {
			params[i * 5 + 4] = firebird.Null{}
		}
	}

	tx.execute('INSERT INTO seo_translations (id, locale_id, product_id, title, description) ${get_merge_source(src)}',
		...params)!
}

// TODO CategorySEO
// TODO rewrite
struct CategorySEOTranslation {
	id              string
	id_bin          []u8
	category_id     string
	category_id_bin []u8
	locale_id       string
	locale_id_bin   []u8
	title           firebird.NullString
	description     firebird.NullString
}

fn model_category_seo_retrieve(mut tx firebird.Transaction, category_ids_bin [][]u8) ![]CategorySEOTranslation {
	data := tx.execute('SELECT id, category_id, locale_id, title, description
		FROM seo_translations
		WHERE category_id IN (${get_placeholders(category_ids_bin)})',
		...workaround_24757(category_ids_bin))!

	rows := data.rows()

	mut seo_translations := []CategorySEOTranslation{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()

		id_bin, _ := v[0].get_array_u8()!
		category_id_bin, _ := v[1].get_array_u8()!
		locale_id_bin, _ := v[2].get_array_u8()!
		title := v[3].get_null_string()!
		description := v[4].get_null_string()!

		id := id_bin_to_string(id_bin)!
		category_id := id_bin_to_string(category_id_bin)!
		locale_id := id_bin_to_string(locale_id_bin)!

		seo_translations[i] = CategorySEOTranslation{
			id:              id
			id_bin:          id_bin
			category_id:     category_id
			category_id_bin: category_id_bin
			locale_id:       locale_id
			locale_id_bin:   locale_id_bin
			title:           title
			description:     description
		}
	}

	return seo_translations
}

struct CategorySEOUpdateParams {
	category_id_bin         []u8
	seo_translation_ids_bin [][]u8
	seo_translations        []SEOTranslationUpdateRequestHygienised
}

fn model_category_seo_update(mut tx firebird.Transaction, p CategorySEOUpdateParams) ! {
	tx.execute('DELETE FROM seo_translations WHERE category_id = ?', p.category_id_bin)!

	mut src := []string{len: p.seo_translations.len}
	mut params := []firebird.Value{len: p.seo_translations.len * 5, init: firebird.Value(firebird.Null{})}
	for i := 0; i < p.seo_translations.len; i++ {
		seo_translation := p.seo_translations[i]
		src[i] = 'SELECT
			CAST(? AS BINARY(16)) AS id,
			CAST(? AS BINARY(16)) AS locale_id,
			CAST(? AS BINARY(16)) AS category_id,
			CAST(? AS VARCHAR(63)) AS title,
			CAST(? AS VARCHAR(191)) AS description
			FROM RDB\$DATABASE'

		params[i * 5] = p.seo_translation_ids_bin[i]
		params[i * 5 + 1] = seo_translation.locale_id_bin
		params[i * 5 + 2] = p.category_id_bin

		if title := seo_translation.title {
			params[i * 5 + 3] = title
		} else {
			params[i * 5 + 3] = firebird.Null{}
		}

		if description := seo_translation.description {
			params[i * 5 + 4] = description
		} else {
			params[i * 5 + 4] = firebird.Null{}
		}
	}

	tx.execute('INSERT INTO seo_translations (id, locale_id, category_id, title, description) ${get_merge_source(src)}',
		...params)!
}
