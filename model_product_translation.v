module peony

import arrays
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

fn parse_product_translation(v []firebird.Value) !ProductTranslation {
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

	return ProductTranslation{
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

fn do_retrieve_product_translations(mut tx firebird.Transaction, product_ids_bin [][]u8) ![]ProductTranslation {
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
		WHERE product_id IN (${get_n_placeholders(i32(product_ids_bin.len))})',
		...workaround_24757(product_ids_bin))!

	mut translations := []ProductTranslation{}
	for i := 0; i < data.rows.len; i++ {
		translation := parse_product_translation(data.rows[i].values)!
		translations = arrays.concat(translations, translation)
	}

	return translations
}

fn (mut app App) do_update_product_translations(mut tx firebird.Transaction, product_id_bin []u8, d []ProductTranslationData) ! {
	mut s := ''
	mut pa := []firebird.Value{}
	for i := 0; i < d.len; i++ {
		s = appendln(s, 'SELECT
			CAST(? AS BINARY(16)) AS product_id,
			CAST(? AS BINARY(163)) AS locale_id,
			CAST(? AS VARCHAR(63)) AS title,
			CAST(? AS VARCHAR(191)) AS subtitle,
			CAST(? AS BLOB SUB_TYPE TEXT) AS description
			FROM RDB\$DATABASE')

		locale_id_bin := id_string_to_bin(d[i].locale_id)! // TODO validate in controller
		pa = arrays.concat(pa, product_id_bin, locale_id_bin)

		if title := d[i].title {
			pa = arrays.concat(pa, title)
		} else {
			pa = arrays.concat(pa, firebird.Null{})
		}

		if subtitle := d[i].subtitle {
			pa = arrays.concat(pa, subtitle)
		} else {
			pa = arrays.concat(pa, firebird.Null{})
		}

		if description := d[i].description {
			pa = arrays.concat(pa, description)
		} else {
			pa = arrays.concat(pa, firebird.Null{})
		}

		if i != d.len - 1 {
			s = appendln(s, 'UNION ALL')
		}
	}

	query := 'MERGE INTO product_translations t
			USING (${s}) s (product_id, locale_id, title, subtitle, description)
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
	pa = arrays.concat(pa, product_id_bin)

	tx.execute(query, ...pa)!
}
