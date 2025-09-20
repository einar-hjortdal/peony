module peony

import arrays
import einar_hjortdal.firebird

fn model_image_create(mut app App, mut tx firebird.Transaction, urls []string) !([]string, [][]u8) {
	mut c := ['id', 'url']
	mut stmt := tx.prepare('INSERT INTO image (${get_columns(c)}) VALUES (${get_placeholders(c)})')!

	mut ids := []string{len: urls.len}
	mut ids_bin := [][]u8{len: urls.len}

	for i := 0; i < urls.len; i++ {
		id, id_bin := app.new_id()
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

struct ProductImage {
	id             string
	id_bin         []u8
	created_at     firebird.DateTime
	updated_at     firebird.DateTime
	deleted_at     firebird.NullDateTime
	url            string
	image_rank     i32
	product_id     string
	product_id_bin []u8
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
	params := arrays.concat([firebird.Value(product_id_bin)], ...workaround_24757(ids_bin))
	tx.execute('DELETE FROM product_image WHERE product_id = ?
		AND image_id IN (${get_placeholders(ids_bin)})',
		...params)!
}

fn model_product_image_retrieve(mut tx firebird.Transaction, product_ids_bin [][]u8) ![]ProductImage {
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
		WHERE pi.product_id IN (${get_placeholders(product_ids_bin)})
		ORDER BY pi.image_rank',
		...workaround_24757(product_ids_bin))!

	rows := data.rows()

	mut product_images := []ProductImage{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()

		id_bin, _ := v[0].get_array_u8()!
		created_at, _ := v[1].get_date_time()!
		updated_at, _ := v[2].get_date_time()!
		deleted_at := v[3].get_null_date_time()!
		url, _ := v[4].get_string()!
		image_rank, _ := v[5].get_i32()!
		product_id_bin, _ := v[6].get_array_u8()!

		id := id_bin_to_string(id_bin)!
		product_id := id_bin_to_string(product_id_bin)!

		product_images[i] = ProductImage{
			id:             id
			id_bin:         id_bin
			created_at:     created_at
			updated_at:     updated_at
			deleted_at:     deleted_at
			url:            url
			image_rank:     image_rank
			product_id:     product_id
			product_id_bin: product_id_bin
		}
	}

	return product_images
}

fn model_product_images_update(mut app App, mut tx firebird.Transaction, product_id_bin []u8, urls []string) ! {
	// always delete all images
	tx.execute('DELETE FROM image i
		WHERE EXISTS (
			SELECT 1
				FROM product_image pi
				WHERE pi.product_id = ?
				AND pi.image_id = i.id
		)',
		product_id_bin)!

	// early return when nothing else to do
	if urls.len == 0 {
		return
	}

	mut image_ids_bin := [][]u8{len: urls.len}
	for i := 0; i < urls.len; i++ {
		_, id_bin := app.new_id()
		image_ids_bin[i] = id_bin
	}

	// insert new images
	mut src := []string{len: urls.len}
	mut params := []firebird.Value{len: urls.len * 2, init: firebird.Value(firebird.Null{})}
	for i := 0; i < urls.len; i++ {
		src[i] = 'SELECT
			CAST(? AS BINARY(16)),
			CAST(? AS BLOB SUB_TYPE TEXT)
			FROM RDB\$DATABASE'
		params[i * 2] = image_ids_bin[i]
		params[i * 2 + 1] = urls[i]
	}

	tx.execute('INSERT INTO image (id, url) ${get_merge_source(src)}', ...params)!

	// insert product_image relation
	src = []string{len: urls.len}
	params = []firebird.Value{len: urls.len * 3, init: firebird.Value(firebird.Null{})}
	for i := 0; i < urls.len; i++ {
		x := i // https://github.com/vlang/v/issues/25354
		src[i] = 'SELECT
			CAST(? AS BINARY(16)),
			CAST(? AS BINARY(16)),
			CAST(? AS INTEGER)
			FROM RDB\$DATABASE'

		params[i * 3] = product_id_bin
		params[i * 3 + 1] = image_ids_bin[i]
		params[i * 3 + 2] = x
	}

	// TODO this merge hangs. What did I do wrong?
	tx.execute('INSERT INTO product_image (product_id, image_id, image_rank) ${get_merge_source(src)}',
		...params)!
}
