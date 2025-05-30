module main

import arrays
import einar_hjortdal.firebird

struct Image {
	id         string
	id_bin     []u8 @[json: '-']
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
		id_bin:     id_bin
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
	id             string
	id_bin         []u8 @[json: '-']
	created_at     firebird.DateTime
	updated_at     firebird.DateTime
	deleted_at     firebird.DateTime @[omitempty]
	url            string
	image_rank     i32
	product_id_bin []u8 @[json: '-']
}

fn parse_product_image(v []firebird.Value) !ProductImage {
	id_bin, _ := v[0].get_array_u8()!
	created_at, _ := v[1].get_date_time()!
	updated_at, _ := v[2].get_date_time()!
	deleted_at, _ := v[3].get_date_time()!
	url, _ := v[4].get_string()!
	image_rank, _ := v[5].get_i32()!
	product_id_bin, _ := v[6].get_array_u8()!

	id := id_bin_to_string(id_bin)!

	return ProductImage{
		id:             id
		id_bin:         id_bin
		created_at:     created_at
		updated_at:     updated_at
		deleted_at:     deleted_at
		url:            url
		image_rank:     image_rank
		product_id_bin: product_id_bin
	}
}

fn (mut app App) do_create_product_images(mut tx firebird.Transaction, product_id_bin []u8, urls []string) ! {
	mut c := ['id', 'url']
	mut stmt := tx.prepare('INSERT INTO image (${get_columns(c)}) VALUES (${get_placeholders(c)})')!

	mut ids_bin := [][]u8{len: urls.len}

	for i := 0; i < urls.len; i++ {
		_, id_bin := app.new_id()!
		ids_bin[i] = id_bin
		stmt.execute(id_bin, urls[i]) or {
			stmt.close()!
			return err
		}
	}
	stmt.close()!

	c = ['product_id', 'image_id']
	stmt = tx.prepare('INSERT INTO product_image (${get_columns(c)}) VALUES (${get_placeholders(c)})')!
	for i := 0; i < urls.len; i++ {
		stmt.execute(product_id_bin, ids_bin[i]) or {
			stmt.close()!
			return err
		}
	}
	stmt.close()!
}

fn do_retrieve_product_images(mut tx firebird.Transaction, product_ids_bin [][]u8) ![]ProductImage {
	data := tx.execute('SELECT 
		i.id, 
		i.created_at,
		i.updated_at,
		i.deleted_at,
		i.url,
		pi.image_rank
		pi.product_id
		FROM product_image pi
		LEFT JOIN image i ON id = image_id
		WHERE pi.product_id IN ${get_n_placeholders(i32(product_ids_bin.len))}
		ORDER BY pi.image_rank',
		...product_ids_bin)!

	mut product_images := []ProductImage{}
	for i := 0; i < data.rows.len; i++ {
		product_image := parse_product_image(data.rows[i].values)!
		product_images = arrays.concat(product_images, product_image)
	}

	return product_images
}

fn do_update_product_images(mut tx firebird.Transaction, product_id_bin []u8, urls []string) ! {
	pi := do_retrieve_product_images(mut tx, [product_id_bin])!
	mut ids_bin_to_prune := [][]u8{}
	for i := 0; i < pi.len; i++ {
		mut to_prune := true
		for k := 0; k < urls.len; k++ {
			if urls[k] == pi[i].url {
				to_prune = false
				break
			}
		}
		if to_prune {
			id_bin := pi[i].id_bin
			ids_bin_to_prune = arrays.concat(ids_bin_to_prune, id_bin)
		}
	}
	// delete all product_image rows with urls that aren't in the provided array
	tx.execute('DELETE FROM product_image WHERE product_id = ?
		AND image_id IN (${get_n_placeholders(i32(ids_bin_to_prune.len))}));',
		...arrays.concat([firebird.Value(product_id_bin)], ...urls))!

	// create image for urls that don't exist in the image table yet
	// create relations for new image rows in product_image
	// update rank according to order in array
}
