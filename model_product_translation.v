module peony

import einar_hjortdal.firebird

struct ProductTranslation {
	product_id     string
	product_id_bin []u8
	locale_id      string
	locale_id_bin  []u8
	created_at     firebird.DateTime
	updated_at     firebird.DateTime
	deleted_at     firebird.DateTime
	title          string
	subtitle       string
	description    string
}

fn model_product_translation_retrieve(mut tx firebird.Transaction, product_ids_bin [][]u8) ![]ProductTranslation {
	data := tx.execute('SELECT
		product_id,
		locale_id,
		created_at,
		updated_at,
		deleted_at,
		title,
		subtitle,
		description
		FROM product_translations
		WHERE product_id IN (${get_placeholders(product_ids_bin)})',
		...workaround_24757(product_ids_bin))!

	rows := data.rows()

	mut translations := []ProductTranslation{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()

		product_id_bin, _ := v[0].get_array_u8()!
		locale_id_bin, _ := v[1].get_array_u8()!
		created_at, _ := v[2].get_date_time()!
		updated_at, _ := v[3].get_date_time()!
		deleted_at, _ := v[4].get_date_time()!
		title, _ := v[5].get_string()!
		subtitle, _ := v[6].get_string()!
		description, _ := v[7].get_string()!

		product_id := id_bin_to_string(product_id_bin)!
		locale_id := id_bin_to_string(locale_id_bin)!

		translations[i] = ProductTranslation{
			product_id:     product_id
			product_id_bin: product_id_bin
			locale_id:      locale_id
			locale_id_bin:  locale_id_bin
			created_at:     created_at
			updated_at:     updated_at
			deleted_at:     deleted_at
			title:          title
			subtitle:       subtitle
			description:    description
		}
	}

	return translations
}

fn model_product_translation_update(mut tx firebird.Transaction, product_id_bin []u8, ph []ProductTranslationRequestHygienised) ! {
	mut src := []string{len: ph.len}
	mut params := []firebird.Value{len: ph.len * 5 + 1, init: firebird.Value(firebird.Null{})}
	for i := 0; i < ph.len; i++ {
		translation := ph[i]
		src[i] = 'SELECT
			CAST(? AS BINARY(16)) AS product_id,
			CAST(? AS BINARY(16)) AS locale_id,
			CAST(? AS VARCHAR(63)) AS title,
			CAST(? AS VARCHAR(191)) AS subtitle,
			CAST(? AS BLOB SUB_TYPE TEXT) AS description
			FROM RDB\$DATABASE'

		params[i * 5] = product_id_bin
		params[i * 5 + 1] = translation.locale_id_bin

		if title := translation.title {
			params[i * 5 + 2] = title
		}

		if subtitle := translation.subtitle {
			params[i * 5 + 3] = subtitle
		}

		if description := translation.description {
			params[i * 5 + 4] = description
		}
	}

	query := 'MERGE INTO product_translations t
			USING (${get_merge_source(src)}) s (product_id, locale_id, title, subtitle, description)
			ON (t.product_id = s.product_id AND t.locale_id = s.locale_id)
			WHEN MATCHED THEN UPDATE SET 
				title = s.title,
				subtitle = s.subtitle,
				description = s.description,
				updated_at = CURRENT_TIMESTAMP
			WHEN NOT MATCHED THEN
				INSERT (product_id, locale_id, title, subtitle, description)
				VALUES (s.product_id, s.locale_id, s.title, s.subtitle, s.description)
			WHEN NOT MATCHED BY SOURCE AND t.product_id = ? THEN
				UPDATE SET deleted_at = CURRENT_TIMESTAMP'
	params[ph.len * 5] = product_id_bin

	println(params)

	tx.execute(query, ...params)!
}
