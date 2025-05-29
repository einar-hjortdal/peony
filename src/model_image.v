module main

import arrays
import einar_hjortdal.firebird

struct Image {
	id         string
	created_at firebird.DateTime
	updated_at firebird.DateTime
	deleted_at firebird.DateTime @[omitempty]
	url        string
}

fn parse_image(v []firebird.Value) !Image {
	id_bin, _ := v[0].get_array_u8()!
	created_at, _ := v[1].get_date_time()!
	updated_at, _ := v[2].get_date_time()!
	deleted_at, _ := v[3].get_date_time()!
	url, _ := v[4].get_string()!

	id := id_bin_to_string(id_bin)!

	return Image{
		id:         id
		created_at: created_at
		updated_at: updated_at
		deleted_at: deleted_at
		url:        url
	}
}

fn do_retrieve_images(mut tx firebird.Transaction, image_ids_bin [][]u8) ![]Image {
	data := tx.execute('SELECT id, created_at, updated_at, deleted_at, url FROM image
		WHERE id IN ${get_n_placeholders(i32(image_ids_bin.len))}',
		...image_ids_bin)!

	mut images := []Image{}
	for i := 0; i < data.rows.len; i++ {
		image := parse_image(data.rows[i].values)!
		images = arrays.concat(images, image)
	}

	return images
}

struct ProductImage {
	product_id string
	image_id   string
}

fn parse_product_image(v []firebird.Value) !ProductImage {
	product_id_bin, _ := v[0].get_array_u8()!
	image_id_bin, _ := v[1].get_array_u8()!

	product_id := id_bin_to_string(product_id_bin)!
	image_id := id_bin_to_string(image_id_bin)!

	return ProductImage{
		product_id: product_id
		image_id:   image_id
	}
}

fn do_retrieve_product_images(mut tx firebird.Transaction, product_ids_bin [][]u8) ![]ProductImage {
	data := tx.execute('SELECT product_id, image_id FROM product_image 
		WHERE product_id IN ${get_n_placeholders(i32(product_ids_bin.len))}',
		...product_ids_bin)!

	mut product_images := []ProductImage{}
	for i := 0; i < data.rows.len; i++ {
		product_image := parse_product_image(data.rows[i].values)!
		product_images = arrays.concat(product_images, product_image)
	}

	return product_images
}
