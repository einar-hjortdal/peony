module main

import einar_hjortdal.firebird

struct ProductTranslations {
	product_id  string
	locale_code string
	created_at  firebird.DateTime
	updated_at  firebird.DateTime
	deleted_at  firebird.DateTime @[omitempty]
	title       string            @[omitempty]
	subtitle    string            @[omitempty]
	description string            @[omitempty]
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
		product_id:  product_id
		locale_code: locale_code
		created_at:  created_at
		updated_at:  updated_at
		deleted_at:  deleted_at
		title:       title
		subtitle:    subtitle
		description: description
	}
}
