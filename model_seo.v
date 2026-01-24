module peony

import arrays
import einar_hjortdal.firebird

struct SEOTranslation {
	seo_id        string
	seo_id_bin    []u8
	locale_id     string
	locale_id_bin []u8
	title         firebird.NullString
	description   firebird.NullString
}

fn model_seo_translation_retrieve(mut tx firebird.Transaction, seo_ids_bin [][]u8) ![]SEOTranslation {
	data := tx.execute('SELECT seo_id, locale_id, title, description
		FROM seo_translations
		WHERE seo_id IN (${get_placeholders(seo_ids_bin)})',
		...workaround_24757(seo_ids_bin))!

	rows := data.rows()

	mut seo_translations := []SEOTranslation{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()

		seo_id_bin, _ := v[0].get_array_u8()!
		locale_id_bin, _ := v[1].get_array_u8()!
		title := v[2].get_null_string()!
		description := v[3].get_null_string()!

		seo_id := id_bin_to_string(seo_id_bin)!
		locale_id := id_bin_to_string(locale_id_bin)!

		seo_translations[i] = SEOTranslation{
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
	translations []SEOTranslation
}

fn model_product_seo_create(mut tx firebird.Transaction, seo_id_bin []u8, product_id_bin []u8) ! {
	tx.execute('INSERT INTO seo (id, product_id) VALUES (?, ?)', seo_id_bin, product_id_bin)!
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

// TODO split in 2: allow empty translations array. An empty translations array means delete all translations.
// This means we can remove the seo delete endpoints
fn model_seo_update(mut tx firebird.Transaction, seo_id_bin []u8, ph SEOUpdateRequestHygienised) ! {
	tx.execute('DELETE FROM seo_translations WHERE seo_id = ?', seo_id_bin)!

	if ph.title != none || ph.description != none {
		mut columns := []string{}
		mut params := []firebird.Value{}
		if title := ph.title {
			columns = arrays.concat(columns, 'title')
			params = arrays.concat(params, title)
		}

		if description := ph.description {
			columns = arrays.concat(columns, 'description')
			params = arrays.concat(params, description)
		}

		params = arrays.concat(params, seo_id_bin)

		tx.execute('UPDATE seo SET ${get_set_columns(columns)} WHERE id = ?', ...params)!
	}

	if translations := ph.translations {
		mut src := []string{len: translations.len}
		mut params := []firebird.Value{len: translations.len * 4, init: firebird.Null{}}
		for i := 0; i < translations.len; i++ {
			translation := translations[i]
			src[i] = 'SELECT
				CAST(? AS BINARY(16)) AS seo_id,
				CAST(? AS BINARY(16)) AS locale_id,
				CAST(? AS VARCHAR(63)) AS title,
				CAST(? AS VARCHAR(191)) AS description
				FROM RDB\$DATABASE'

			params[i * 4] = seo_id_bin
			params[i * 4 + 1] = translation.locale_id_bin

			if title := translation.title {
				params[i * 4 + 2] = title
			} else {
				params[i * 4 + 2] = firebird.Null{}
			}

			if description := translation.description {
				params[i * 4 + 3] = description
			} else {
				params[i * 4 + 3] = firebird.Null{}
			}
		}

		tx.execute('INSERT INTO seo_translations (seo_id, locale_id, title, description) ${get_merge_source(src)}',
			...params)!
	}
}

// Does not delete the seo row: sets title and description to null, deletes all translations.
fn model_seo_delete(mut tx firebird.Transaction, seo_id_bin []u8) ! {
	tx.execute('UPDATE seo SET title = NULL, description = NULL WHERE id = ?', seo_id_bin)!
	tx.execute('DELETE FROM seo_translations WHERE seo_id = ?', seo_id_bin)!
}

struct CategorySEO {
	id              string
	id_bin          []u8
	category_id     string
	category_id_bin []u8
	title           firebird.NullString
	description     firebird.NullString
mut:
	translations []SEOTranslation
}

fn model_category_seo_create(mut tx firebird.Transaction, seo_id_bin []u8, category_id_bin []u8) ! {
	tx.execute('INSERT INTO seo (id, category_id) VALUES (?, ?)', seo_id_bin, category_id_bin)!
}

fn model_category_seo_retrieve(mut tx firebird.Transaction, category_ids_bin [][]u8) ![]CategorySEO {
	data := tx.execute('SELECT id, category_id, title, description FROM seo
		WHERE category_id IN (${get_placeholders(category_ids_bin)})',
		...workaround_24757(category_ids_bin))!

	rows := data.rows()

	mut category_seo := []CategorySEO{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()

		id_bin, _ := v[0].get_array_u8()!
		product_id_bin, _ := v[1].get_array_u8()!
		title := v[2].get_null_string()!
		description := v[3].get_null_string()!

		id := id_bin_to_string(id_bin)!
		product_id := id_bin_to_string(product_id_bin)!

		category_seo[i] = CategorySEO{
			id:              id
			id_bin:          id_bin
			category_id:     product_id
			category_id_bin: product_id_bin
			title:           title
			description:     description
		}
	}

	return category_seo
}
