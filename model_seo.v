module peony

import einar_hjortdal.firebird

struct ProductSEOTranslation {
	id             string
	id_bin         []u8
	product_id     string
	product_id_bin []u8
	locale_id      string
	locale_id_bin  []u8
	title          firebird.NullString
	description    firebird.NullString
}

fn model_product_seo_retrieve(mut tx firebird.Transaction, product_ids_bin [][]u8) ![]ProductSEOTranslation {
	data := tx.execute('SELECT id, product_id, locale_id, title, description
		FROM seo_translations
		WHERE product_id IN (${get_placeholders(product_ids_bin)})',
		...workaround_24757(product_ids_bin))!

	rows := data.rows()

	mut seo_translations := []ProductSEOTranslation{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()

		id_bin, _ := v[0].get_array_u8()!
		product_id_bin, _ := v[1].get_array_u8()!
		locale_id_bin, _ := v[2].get_array_u8()!
		title := v[3].get_null_string()!
		description := v[4].get_null_string()!

		id := id_bin_to_string(id_bin)!
		product_id := id_bin_to_string(product_id_bin)!
		locale_id := id_bin_to_string(locale_id_bin)!

		seo_translations[i] = ProductSEOTranslation{
			id:             id
			id_bin:         id_bin
			product_id:     product_id
			product_id_bin: product_id_bin
			locale_id:      locale_id
			locale_id_bin:  locale_id_bin
			title:          title
			description:    description
		}
	}

	return seo_translations
}

// TODO think more on this struct definition, it still contains a Request struct and I don't like that
struct ProductSEOUpdateParams {
	product_id_bin          []u8
	seo_translation_ids_bin [][]u8
	seo_translations        []SEOTranslationUpdateRequestHygienised
}

// replaces all seo_translations related to product_id with new ones
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

		params[i * 4] = p.seo_translation_ids_bin[i]
		params[i * 4 + 1] = seo_translation.locale_id_bin
		params[i * 4 + 2] = p.product_id_bin

		if title := seo_translation.title {
			params[i * 4 + 3] = title
		} else {
			params[i * 4 + 3] = firebird.Null{}
		}

		if description := seo_translation.description {
			params[i * 4 + 4] = description
		} else {
			params[i * 4 + 4] = firebird.Null{}
		}
	}

	tx.execute('INSERT INTO seo_translations (id, locale_id, product_id, title, description) ${get_merge_source(src)}',
		...params)!
}

struct ProductCategorySEOTranslation {
	id                      string
	id_bin                  []u8
	product_category_id     string
	product_category_id_bin []u8
	locale_id               string
	locale_id_bin           []u8
	title                   firebird.NullString
	description             firebird.NullString
}

// TODO use
fn model_product_category_seo_retrieve(mut tx firebird.Transaction, product_category_ids_bin [][]u8) ![]ProductCategorySEOTranslation {
	data := tx.execute('SELECT id, product_category_id, locale_id, title, description
		FROM seo_translations
		WHERE product_category_id IN (${get_placeholders(product_category_ids_bin)})',
		...workaround_24757(product_category_ids_bin))!

	rows := data.rows()

	mut seo_translations := []ProductCategorySEOTranslation{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()

		id_bin, _ := v[0].get_array_u8()!
		product_category_id_bin, _ := v[1].get_array_u8()!
		locale_id_bin, _ := v[2].get_array_u8()!
		title := v[3].get_null_string()!
		description := v[4].get_null_string()!

		id := id_bin_to_string(id_bin)!
		product_category_id := id_bin_to_string(product_category_id_bin)!
		locale_id := id_bin_to_string(locale_id_bin)!

		seo_translations[i] = ProductCategorySEOTranslation{
			id:                      id
			id_bin:                  id_bin
			product_category_id:     product_category_id
			product_category_id_bin: product_category_id_bin
			locale_id:               locale_id
			locale_id_bin:           locale_id_bin
			title:                   title
			description:             description
		}
	}

	return seo_translations
}
