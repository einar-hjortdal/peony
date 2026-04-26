module peony

import arrays
import einar_hjortdal.firebird

struct SEOTranslation {
	seo_id      ID
	locale_id   ID
	title       firebird.NullString
	description firebird.NullString
}

struct SEO {
	id          ID
	title       firebird.NullString
	description firebird.NullString
mut:
	translations []SEOTranslation
}

fn (seo SEO) id() ID {
	return seo.id
}

fn model_seo_translation_retrieve(mut tx firebird.Transaction, seo_ids []ID) ![]SEOTranslation {
	data := tx.execute('SELECT seo_id, locale_id, title, description
		FROM seo_translations
		WHERE seo_id IN (${get_placeholders(seo_ids)})',
		...ids_bytes(seo_ids))!

	rows := data.rows()

	mut seo_translations := []SEOTranslation{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()

		seo_id_bin, _ := v[0].get_array_u8()!
		locale_id_bin, _ := v[1].get_array_u8()!
		title := v[2].get_null_string()!
		description := v[3].get_null_string()!

		seo_id := id_from_bytes(seo_id_bin)!
		locale_id := id_from_bytes(locale_id_bin)!

		seo_translations[i] = SEOTranslation{
			seo_id:      seo_id
			locale_id:   locale_id
			title:       title
			description: description
		}
	}

	return seo_translations
}

struct ProductSEO {
	SEO
	product_id ID
}

fn model_product_seo_create_default(mut tx firebird.Transaction, seo_id ID, product_id ID) ! {
	tx.execute('INSERT INTO seo (id, product_id) VALUES (?, ?)', seo_id.bytes(), product_id.bytes())!
}

fn model_product_seo_create(mut tx firebird.Transaction, seo_id ID, product_id ID, ph SEORequestHygienised) ! {
	mut columns := ['id', 'product_id']
	mut params := [firebird.Value(seo_id.bytes()), product_id.bytes()]
	if title := ph.title {
		columns = arrays.concat(columns, 'title')
		if title == '' {
			params = arrays.concat(params, firebird.Null{})
		} else {
			params = arrays.concat(params, title)
		}
	}

	if description := ph.description {
		columns = arrays.concat(columns, 'description')
		if description == '' {
			params = arrays.concat(params, firebird.Null{})
		} else {
			params = arrays.concat(params, description)
		}
	}

	tx.execute('INSERT INTO seo (${get_columns(columns)}) VALUES (${get_placeholders(columns)})',
		...params)!
}

fn model_product_seo_retrieve(mut tx firebird.Transaction, product_ids_bin [][]u8) ![]ProductSEO {
	data := tx.execute('SELECT id, product_id, title, description FROM seo
		WHERE product_id IN (${get_placeholders(product_ids_bin)})',
		...product_ids_bin)!

	rows := data.rows()

	mut product_seo := []ProductSEO{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()

		id_bin, _ := v[0].get_array_u8()!
		product_id_bin, _ := v[1].get_array_u8()!
		title := v[2].get_null_string()!
		description := v[3].get_null_string()!

		id := id_from_bytes(id_bin)!
		product_id := id_from_bytes(product_id_bin)!

		product_seo[i] = ProductSEO{
			id:          id
			product_id:  product_id
			title:       title
			description: description
		}
	}

	return product_seo
}

fn model_seo_update(mut tx firebird.Transaction, seo_id ID, ph SEORequestHygienised) ! {
	mut columns := []string{}
	mut params := []firebird.Value{}
	if title := ph.title {
		columns = arrays.concat(columns, 'title')
		if title == '' {
			params = arrays.concat(params, firebird.Null{})
		} else {
			params = arrays.concat(params, title)
		}
	}

	if description := ph.description {
		columns = arrays.concat(columns, 'description')
		if description == '' {
			params = arrays.concat(params, firebird.Null{})
		} else {
			params = arrays.concat(params, description)
		}
	}

	params = arrays.concat(params, seo_id.bytes())

	tx.execute('UPDATE seo SET ${get_set_columns(columns)} WHERE id = ?', ...params)!
}

fn model_seo_translations_delete(mut tx firebird.Transaction, seo_id ID) ! {
	tx.execute('DELETE FROM seo_translations WHERE seo_id = ?', seo_id.bytes())!
}

fn model_seo_translations_create(mut tx firebird.Transaction, seo_id ID, translations []SEOTranslationRequestHygienised) ! {
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

		params[i * 4] = seo_id.bytes()
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

struct CategorySEO {
	SEO
	category_id ID
}

fn model_category_seo_create_default(mut tx firebird.Transaction, seo_id ID, category_id ID) ! {
	tx.execute('INSERT INTO seo (id, category_id) VALUES (?, ?)', seo_id.bytes(),
		category_id.bytes())!
}

fn model_category_seo_create(mut tx firebird.Transaction, seo_id ID, category_id ID, ph SEORequestHygienised) ! {
	mut columns := ['id', 'category_id']
	mut params := [firebird.Value(seo_id.bytes()), category_id.bytes()]
	if title := ph.title {
		columns = arrays.concat(columns, 'title')
		if title == '' {
			params = arrays.concat(params, firebird.Null{})
		} else {
			params = arrays.concat(params, title)
		}
	}

	if description := ph.description {
		columns = arrays.concat(columns, 'description')
		if description == '' {
			params = arrays.concat(params, firebird.Null{})
		} else {
			params = arrays.concat(params, description)
		}
	}

	tx.execute('INSERT INTO seo (${get_columns(columns)}) VALUES (${get_placeholders(columns)})',
		...params)!
}

fn model_category_seo_retrieve(mut tx firebird.Transaction, category_ids []ID) ![]CategorySEO {
	data := tx.execute('SELECT id, category_id, title, description FROM seo
		WHERE category_id IN (${get_placeholders(category_ids)})',
		...ids_bytes(category_ids))!

	rows := data.rows()

	mut category_seo := []CategorySEO{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()

		id_bin, _ := v[0].get_array_u8()!
		product_id_bin, _ := v[1].get_array_u8()!
		title := v[2].get_null_string()!
		description := v[3].get_null_string()!

		id := id_from_bytes(id_bin)!
		product_id := id_from_bytes(product_id_bin)!

		category_seo[i] = CategorySEO{
			id:          id
			category_id: product_id
			title:       title
			description: description
		}
	}

	return category_seo
}

