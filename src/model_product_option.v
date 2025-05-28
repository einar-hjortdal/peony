module main

import arrays
import einar_hjortdal.firebird

struct ProductOptionTranslation {
	product_option_id string
	locale_code       string
	title             string
}

fn parse_product_option_translation(v []firebird.Value) !ProductOptionTranslation {
	product_option_id_bin, _ := v[0].get_array_u8()!
	locale_code, _ := v[1].get_string()!
	title, _ := v[2].get_string()!

	product_option_id := id_bin_to_string(product_option_id_bin)!

	return ProductOptionTranslation{
		product_option_id: product_option_id
		locale_code:       locale_code
		title:             title
	}
}

struct ProductOption {
	id           string
	created_at   firebird.DateTime
	updated_at   firebird.DateTime
	deleted_at   firebird.DateTime @[omitempty]
	product_id   string
	translations []ProductOptionTranslation
}

fn parse_product_option(v []firebird.Value) !ProductOption {
	id_bin, _ := v[0].get_array_u8()!
	created_at, _ := v[1].get_date_time()!
	updated_at, _ := v[2].get_date_time()!
	deleted_at, _ := v[3].get_date_time()!
	product_id_bin, _ := v[4].get_array_u8()!

	id := id_bin_to_string(id_bin)!
	product_id := id_bin_to_string(product_id_bin)!

	return ProductOption{
		id:         id
		created_at: created_at
		updated_at: updated_at
		deleted_at: deleted_at
		product_id: product_id
	}
}

fn (mut app App) do_retrieve_product_option_translations(mut tx firebird.Transaction, po []ProductOption) ![]ProductOptionTranslation {
	mut ids_bin := [][]u8{}
	for i := 0; i < po.len; i++ {
		id_bin := id_string_to_bin(po[i].id)!
		ids_bin = arrays.concat(ids_bin, id_bin)
	}

	data := tx.execute('SELECT product_option_id, locale_code, title
		FROM product_option_translations
		WHERE id IN ${get_n_placeholders(i32(ids_bin.len))}',
		...ids_bin)!

	mut translations := []ProductOptionTranslation{}
	for i := 0; i < data.rows.len; i++ {
		translation := parse_product_option_translation(data.rows[i].values)!
		translations = arrays.concat(translations, translation)
	}

	return translations
}

struct ProductOptionValueTranslation {
	product_option_value_id string
	locale_code             string
	name                    string
}

struct ProductOptionValue {
	id           string
	created_at   firebird.DateTime
	updated_at   firebird.DateTime
	deleted_at   firebird.DateTime @[omitempty]
	option_id    string
	variant_id   string
	translations []ProductOptionValueTranslation
}
