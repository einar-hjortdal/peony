module peony

import arrays
import einar_hjortdal.firebird

struct Image {
	id         string
	id_bin     []u8
	created_at firebird.DateTime
	updated_at firebird.DateTime
	deleted_at firebird.DateTime
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

fn (mut app App) do_create_images(mut tx firebird.Transaction, urls []string) !([]string, [][]u8) {
	mut c := ['id', 'url']
	mut stmt := tx.prepare('INSERT INTO image (${get_columns(c)}) VALUES (${get_placeholders(c)})')!

	mut ids := []string{len: urls.len}
	mut ids_bin := [][]u8{len: urls.len}

	for i := 0; i < urls.len; i++ {
		id, id_bin := app.new_id()!
		ids[i] = id
		ids_bin[i] = id_bin
		stmt.execute(id_bin, urls[i]) or {
			stmt.close()!
			return err
		}
	}
	stmt.close()!
	return ids, ids_bin
}

fn do_retrieve_images(mut tx firebird.Transaction, image_ids_bin [][]u8) ![]Image {
	data := tx.execute('SELECT id, created_at, updated_at, deleted_at, url FROM image
		WHERE id IN (${get_n_placeholders(i32(image_ids_bin.len))})',
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

fn (mut app App) do_create_product_images(mut tx firebird.Transaction, product_id_bin []u8, ids_bin [][]u8) ! {
	c := ['product_id', 'image_id', 'image_rank']
	mut stmt := tx.prepare('INSERT INTO product_image (${get_columns(c)}) VALUES (${get_placeholders(c)})')!
	for i := 0; i < ids_bin.len; i++ {
		rank := i
		stmt.execute(product_id_bin, ids_bin[i], rank) or {
			stmt.close()!
			return err
		}
	}
	stmt.close()!
}

fn do_delete_product_images(mut tx firebird.Transaction, product_id_bin []u8, ids_bin [][]u8) ! {
	params := arrays.concat([firebird.Value(product_id_bin)], ...ids_bin)
	tx.execute('DELETE FROM product_image WHERE product_id = ?
		AND image_id IN (${get_n_placeholders(i32(ids_bin.len))}));',
		...params)!
}

fn do_retrieve_product_images(mut tx firebird.Transaction, product_ids_bin [][]u8) ![]ProductImage {
	data := tx.execute('SELECT
		i.id,
		i.created_at,
		i.updated_at,
		i.deleted_at,
		i.url,
		pi.image_rank,
		pi.product_id
		FROM product_image pi
		LEFT JOIN image i ON id = image_id
		WHERE pi.product_id IN (${get_n_placeholders(i32(product_ids_bin.len))})
		ORDER BY pi.image_rank',
		...workaround_24757(product_ids_bin))!

	mut product_images := []ProductImage{}
	for i := 0; i < data.rows.len; i++ {
		product_image := parse_product_image(data.rows[i].values)!
		product_images = arrays.concat(product_images, product_image)
	}

	return product_images
}

fn (mut app App) do_update_product_images(mut tx firebird.Transaction, product_id_bin []u8, urls []string) ! {
	pi := do_retrieve_product_images(mut tx, [product_id_bin])!

	// delete all product_images with url missing from the given array
	mut ids_bin_to_prune := [][]u8{}
	for i := 0; i < pi.len; i++ {
		mut found := false
		for k := 0; k < urls.len; k++ {
			if urls[k] == pi[i].url {
				found = true
				break
			}
		}
		if !found {
			ids_bin_to_prune = arrays.concat(ids_bin_to_prune, pi[i].id_bin)
		}
	}

	do_delete_product_images(mut tx, product_id_bin, ids_bin_to_prune)!

	// create image for urls that don't exist in the image table yet
	mut images_to_create := []string{}
	for i := 0; i < urls.len; i++ {
		mut found := false
		for k := 0; k < pi.len; k++ {
			if urls[i] == pi[k].url {
				found = true
				break
			}
		}
		if !found {
			images_to_create = arrays.concat(images_to_create, urls[i])
		}
	}

	_, created_ids_bin := app.do_create_images(mut tx, images_to_create)!

	// sort ids_bin according to urls array to obtain the correct image_rank order
	mut sorted_ids_bin := [][]u8{}
	for i := 0; i < urls.len; i++ {
		url := urls[i]
		mut found := false

		for k := 0; k < pi.len; k++ {
			if pi[k].url == url {
				sorted_ids_bin = arrays.concat(sorted_ids_bin, pi[k].id_bin)
				found = true
				break
			}
		}

		if found {
			continue
		}

		for k := 0; k < images_to_create.len; k++ {
			if images_to_create[k] == url {
				sorted_ids_bin = arrays.concat(sorted_ids_bin, created_ids_bin[k])
				break
			}
		}
	}

	mut s := ''
	mut params := []firebird.Value{}
	for i := 0; i < sorted_ids_bin.len; i++ {
		image_rank := i
		s = appendln(s, 'SELECT ? AS product_id, ? AS image_id, ? AS image_rank FROM RDB\$DATABASE')
		params = arrays.concat(params, product_id_bin, sorted_ids_bin[i], image_rank)
		if i < sorted_ids_bin.len - 1 {
			s = appendln(s, 'UNION ALL')
		}
	}

	tx.execute('MERGE INTO product_image t
		USING (${s}) s
			ON (t.product_id = s.product_id AND t.image_id = s.image_id)
			WHEN MATCHED THEN UPDATE SET image_rank = s.image_rank
			WHEN NOT MATCHED THEN
				INSERT (product_id, image_id, image_rank)
				VALUES (s.product_id, s.image_id, s.image_rank);',
		...params)!
}
