module peony

import arrays
import einar_hjortdal.firebird

struct ImageTranslation {
	image_id      string
	image_id_bin  []u8
	locale_id     string
	locale_id_bin []u8
	alt           string
}

fn model_image_translation_retrieve(mut tx firebird.Transaction, image_ids_bin [][]u8) ![]ImageTranslation {
	data := tx.execute('SELECT image_id, locale_id, alt FROM image_translations
		WHERE image_id IN (${get_placeholders(image_ids_bin)})',
		...workaround_24757(image_ids_bin))!

	rows := data.rows()

	mut image_translations := []ImageTranslation{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()

		image_id_bin, _ := v[0].get_array_u8()!
		locale_id_bin, _ := v[1].get_array_u8()!
		alt, _ := v[2].get_string()!

		image_id := id_bin_to_string(image_id_bin)!
		locale_id := id_bin_to_string(locale_id_bin)!

		image_translations[i] = ImageTranslation{
			image_id:      image_id
			image_id_bin:  image_id_bin
			locale_id:     locale_id
			locale_id_bin: locale_id_bin
			alt:           alt
		}
	}

	return image_translations
}

struct ProductImage {
	id             string
	id_bin         []u8
	url            string
	image_rank     i32
	product_id     string
	product_id_bin []u8
	alt            firebird.NullString
mut:
	translations []ImageTranslation
}

fn model_product_image_retrieve(mut tx firebird.Transaction, locale_id_bin []u8, product_ids_bin [][]u8) ![]ProductImage {
	mut params := []firebird.Value{}

	if locale_id_bin.len > 0 {
		params = arrays.concat(params, locale_id_bin, locale_id_bin)
	} else {
		params = arrays.concat(params, firebird.Null{}, firebird.Null{})
	}

	params = arrays.concat(params, ...workaround_24757(product_ids_bin))

	data := tx.execute('SELECT
		i.id,
		i.url,
		pi.image_rank,
		pi.product_id,
		COALESCE(it_requested.alt, it_default.alt) AS alt
		FROM product_image pi
		LEFT JOIN image i ON id = image_id
		LEFT JOIN image_translations it_default
			ON it_default.image_id = i.id
			AND it_default.locale_id = (
				SELECT default_locale_id FROM store
			)
		LEFT JOIN image_translations it_requested
			ON CAST(? AS BINARY(16)) IS NOT NULL
			AND it_requested.image_id = i.id
			AND it_requested.locale_id = ?
		WHERE pi.product_id IN (${get_placeholders(product_ids_bin)})
		ORDER BY pi.image_rank',
		...params)!

	rows := data.rows()

	mut product_images := []ProductImage{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()

		id_bin, _ := v[0].get_array_u8()!
		url, _ := v[1].get_string()!
		image_rank, _ := v[2].get_i32()!
		product_id_bin, _ := v[3].get_array_u8()!
		alt := v[4].get_null_string()!

		id := id_bin_to_string(id_bin)!
		product_id := id_bin_to_string(product_id_bin)!

		product_images[i] = ProductImage{
			id:             id
			id_bin:         id_bin
			url:            url
			image_rank:     image_rank
			product_id:     product_id
			product_id_bin: product_id_bin
			alt:            alt
		}
	}

	return product_images
}

fn model_product_images_update(mut app App, mut tx firebird.Transaction, product_id_bin []u8, images []ImageRequestHygienised) ! {
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
	if images.len == 0 {
		return
	}

	mut image_ids_bin := [][]u8{len: images.len}
	for i := 0; i < images.len; i++ {
		_, id_bin := app.new_id()
		image_ids_bin[i] = id_bin
	}

	// insert new images
	mut src := []string{len: images.len}
	mut params := []firebird.Value{len: images.len * 2, init: firebird.Value(firebird.Null{})}
	for i := 0; i < images.len; i++ {
		src[i] = 'SELECT
			CAST(? AS BINARY(16)),
			CAST(? AS BLOB SUB_TYPE TEXT)
			FROM RDB\$DATABASE'
		params[i * 2] = image_ids_bin[i]
		params[i * 2 + 1] = images[i].url
	}

	tx.execute('INSERT INTO image (id, url) ${get_merge_source(src)}', ...params)!

	// insert translations
	src = []string{}
	params = []firebird.Value{}
	for i := 0; i < images.len; i++ {
		image_id := image_ids_bin[i]
		translations := images[i].translations
		if translations.len > 0 {
			for k := 0; k < translations.len; k++ {
				translation := translations[k]
				locale_id := translation.locale_id
				alt := translation.alt
				src = arrays.concat(src, 'SELECT
			CAST(? AS BINARY(16)),
			CAST(? AS BINARY(16)),
			CAST(? AS VARCHAR(191))
			FROM RDB\$DATABASE')
				params = arrays.concat(params, image_id, locale_id, alt)
			}
		}
	}

	if src.len > 0 {
		tx.execute('INSERT INTO image_translations (image_id, locale_id, alt) ${get_merge_source(src)}',
			...params)!
	}

	// insert product_image relation
	src = []string{len: images.len}
	params = []firebird.Value{len: images.len * 3, init: firebird.Value(firebird.Null{})}
	for i := 0; i < images.len; i++ {
		src[i] = 'SELECT
			CAST(? AS BINARY(16)),
			CAST(? AS BINARY(16)),
			CAST(? AS INTEGER)
			FROM RDB\$DATABASE'

		params[i * 3] = product_id_bin
		params[i * 3 + 1] = image_ids_bin[i]
		params[i * 3 + 2] = i32(i)
	}

	tx.execute('INSERT INTO product_image (product_id, image_id, image_rank) ${get_merge_source(src)}',
		...params)!
}
