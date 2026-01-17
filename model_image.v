module peony

// import arrays
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

struct UserImage {
	id     string
	id_bin []u8
	url    string
	alt    firebird.NullString
mut:
	translations []ImageTranslation
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

fn model_product_image_retrieve(mut tx firebird.Transaction, product_ids_bin [][]u8) ![]ProductImage {
	data := tx.execute('SELECT
		i.id,
		i.url,
		i.alt,
		pi.image_rank,
		pi.product_id
		FROM image i
		LEFT JOIN product_image pi
		ON i.id = pi.image_id
		WHERE pi.product_id IN (${get_placeholders(product_ids_bin)})
		ORDER BY pi.image_rank',
		...workaround_24757(product_ids_bin))!

	rows := data.rows()

	mut product_images := []ProductImage{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()

		id_bin, _ := v[0].get_array_u8()!
		url, _ := v[1].get_string()!
		alt := v[2].get_null_string()!
		image_rank, _ := v[3].get_i32()!
		product_id_bin, _ := v[4].get_array_u8()!

		id := id_bin_to_string(id_bin)!
		product_id := id_bin_to_string(product_id_bin)!

		product_images[i] = ProductImage{
			id:             id
			id_bin:         id_bin
			url:            url
			alt:            alt
			image_rank:     image_rank
			product_id:     product_id
			product_id_bin: product_id_bin
		}
	}

	return product_images
}

fn model_product_images_update(mut tx firebird.Transaction, product_id_bin []u8, images []ImageRequestHygienised, image_ids_bin [][]u8) ! {
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

	// insert new images
	mut src := []string{len: images.len}
	mut params := []firebird.Value{len: images.len * 3, init: firebird.Null{}}
	mut translation_n := i32(0)
	for i := 0; i < images.len; i++ {
		image := images[i]
		src[i] = 'SELECT
			CAST(? AS BINARY(16)),
			CAST(? AS BLOB SUB_TYPE TEXT),
			CAST(? AS VARCHAR(191))
			FROM RDB\$DATABASE'
		params[i * 3] = image_ids_bin[i]
		params[i * 3 + 1] = image.url
		if alt := image.alt {
			params[i * 3 + 2] = alt
		} else {
			params[i * 3 + 2] = firebird.Null{}
		}

		// compute number of tranlsations to insert
		if translations := image.translations {
			translation_n += translations.len
		}
	}

	tx.execute('INSERT INTO image (id, url, alt) ${get_merge_source(src)}', ...params)!

	// insert translations if any
	if translation_n > 0 {
		src = []string{len: translation_n}
		params = []firebird.Value{len: translation_n * 3, init: firebird.Null{}}
		mut current_translation_i := i32(0)
		for i := 0; i < images.len; i++ {
			image_id := image_ids_bin[i]
			if translations := images[i].translations {
				for k := 0; k < translations.len; k++ {
					translation := translations[k]
					locale_id := translation.locale_id
					alt := translation.alt
					src[current_translation_i] = 'SELECT
						CAST(? AS BINARY(16)),
						CAST(? AS BINARY(16)),
						CAST(? AS VARCHAR(191))
						FROM RDB\$DATABASE'

					params[current_translation_i * 3] = image_id
					params[current_translation_i * 3 + 1] = locale_id
					params[current_translation_i * 3 + 2] = alt
				}

				current_translation_i++
			}
		}

		tx.execute('INSERT INTO image_translations (image_id, locale_id, alt) ${get_merge_source(src)}',
			...params)!
	}

	// insert product_image relation
	src = []string{len: images.len}
	params = []firebird.Value{len: images.len * 3, init: firebird.Null{}}
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
