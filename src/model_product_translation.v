module main

import arrays
import einar_hjortdal.firebird

struct ProductTranslations {
	product_id     string
	product_id_bin []u8 @[json: '-']
	locale_code    string
	created_at     firebird.DateTime
	updated_at     firebird.DateTime
	deleted_at     firebird.DateTime @[omitempty]
	title          string            @[omitempty]
	subtitle       string            @[omitempty]
	description    string            @[omitempty]
}

fn parse_product_translation(v []firebird.Value) !ProductTranslations {
	product_id_bin, _ := v[0].get_array_u8()!
	locale_code, _ := v[1].get_string()!
	created_at, _ := v[2].get_date_time()!
	updated_at, _ := v[3].get_date_time()!
	deleted_at, _ := v[4].get_date_time()!
	title, _ := v[5].get_string()!
	subtitle, _ := v[6].get_string()!
	description, _ := v[7].get_string()!

	product_id := id_bin_to_string(product_id_bin)!

	return ProductTranslations{
		product_id:     product_id
		product_id_bin: product_id_bin
		locale_code:    locale_code
		created_at:     created_at
		updated_at:     updated_at
		deleted_at:     deleted_at
		title:          title
		subtitle:       subtitle
		description:    description
	}
}

fn do_retrieve_product_translations(mut tx firebird.Transaction, product_ids_bin [][]u8) ![]ProductTranslations {
	data := tx.execute('SELECT 
		product_id,
		locale_code,
		created_at,
		updated_at,
		deleted_at,
		title,
		subtitle,
		description
		FROM product_translations
		WHERE product_id IN ${get_n_placeholders(i32(product_ids_bin.len))}',
		...product_ids_bin)!

	mut translations := []ProductTranslations{}
	for i := 0; i < data.rows.len; i++ {
		translation := parse_product_translation(data.rows[i].values)!
		translations = arrays.concat(translations, translation)
	}

	return translations
}

struct UpdateProductTranslationData {
	locale_code string
	title       ?string
	subtitle    ?string
	description ?string
}

fn (mut app App) do_update_product_translations(mut tx firebird.Transaction, product_id_bin []u8, d []UpdateProductTranslationData) ! {
	mut s := ''
	mut pa := [firebird.Value(product_id_bin)]
	for i := 0; i < d.len; i++ {
		s = appendln(s, 'SELECT
				? AS product_id,
				? AS locale_code,
				? AS title,
				? AS subtitle,
				? AS description,
				FROM RDB\$DATABASE')

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

	query := 'MERGE INTO product_translations T
			USING (${s}) S (product_id, locale_code, title, subtitle, description)
			ON (T.product_id = S.product_id AND T.locale_code = S.locale_code)
			WHEN MATCHED THEN UPDATE SET 
				title = S.title,
				subtitle = S.subtitle,
				description = S.description,
				updated_at = CURRENT_TIMESTAMP
			WHEN NOT MATCHED THEN
			INSERT (product_id, locale_code, title, subtitle, description, created_at, updated_at)
			VALUES (S.product_id, S.locale_code, S.title, S.subtitle, S.description, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
			WHEN NOT MATCHED BY SOURCE AND T.product_id = ? THEN DELETE'
	pa = arrays.concat(pa, product_id_bin)

	tx.execute(query, ...pa)!
}
