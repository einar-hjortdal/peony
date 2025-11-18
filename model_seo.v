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
	data := tx.execute('SELECT id, category_id, locale_id, title, description
		FROM seo_translations
		WHERE category_id IN (${get_placeholders(product_category_ids_bin)})',
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
