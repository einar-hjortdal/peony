module record

// import arrays
import einar_hjortdal.firebird

pub struct ImageTranslation {
pub:
	image_id  ID
	locale_id ID
	alt       string
}

pub fn (it ImageTranslation) locale_id() ID {
	return it.locale_id
}

pub fn image_translation_retrieve(mut tx firebird.Transaction, image_ids []ID) ![]ImageTranslation {
	data := tx.execute('SELECT image_id, locale_id, alt FROM image_translations
		WHERE image_id IN (${get_placeholders(image_ids)})',
		...ids_bytes(image_ids))!

	rows := data.rows()

	mut image_translations := []ImageTranslation{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()

		image_id_bin, _ := v[0].get_array_u8()!
		locale_id_bin, _ := v[1].get_array_u8()!
		alt, _ := v[2].get_string()!

		image_id := id_from_bytes(image_id_bin)!
		locale_id := id_from_bytes(locale_id_bin)!

		image_translations[i] = ImageTranslation{
			image_id:  image_id
			locale_id: locale_id
			alt:       alt
		}
	}

	return image_translations
}

pub struct Image {
pub:
	id  ID
	url string
	alt ?string
pub mut:
	translations []ImageTranslation
}

pub fn (img Image) id() ID {
	return img.id
}

pub struct UserImage {
	Image
pub:
	user_id ID
}

pub struct ProductImage {
	Image
pub:
	product_id ID
	image_rank i32
}

pub fn product_image_retrieve(mut tx firebird.Transaction, product_ids []ID) ![]ProductImage {
	data := tx.execute('SELECT
		i.id,
		i.url,
		i.alt,
		pi.image_rank,
		pi.product_id
		FROM image i
		LEFT JOIN product_image pi
		ON i.id = pi.image_id
		WHERE pi.product_id IN (${get_placeholders(product_ids)})
		ORDER BY pi.image_rank',
		...ids_bytes(product_ids))!

	rows := data.rows()

	mut product_images := []ProductImage{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()

		id_bin, _ := v[0].get_array_u8()!
		url, _ := v[1].get_string()!
		alt := v[2].get_null_string()!
		image_rank, _ := v[3].get_i32()!
		product_id_bin, _ := v[4].get_array_u8()!

		id := id_from_bytes(id_bin)!
		product_id := id_from_bytes(product_id_bin)!

		product_images[i] = ProductImage{
			id:         id
			url:        url
			alt:        alt.none_value()
			image_rank: image_rank
			product_id: product_id
		}
	}

	return product_images
}

// delete all product images belonging to one product
pub fn product_image_delete(mut tx firebird.Transaction, product_id ID) ! {
	tx.execute('DELETE FROM image i
		WHERE EXISTS (
			SELECT 1 FROM product_image pi
			WHERE pi.product_id = ?
			AND pi.image_id = i.id
		)',
		product_id.bytes())!
}

pub struct ImageTranslationCreateParams {
pub:
	image_id  ID
	locale_id ID
	alt       string
}

pub struct ProductImageCreateParams {
pub:
	id           ID
	url          string
	alt          ?string
	image_rank   i32
	translations ?[]ImageTranslationCreateParams
}

// TODO split operations
pub fn product_image_create(mut tx firebird.Transaction, product_id ID, images []ProductImageCreateParams) ! {
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
		params[i * 3] = image.id.bytes()
		params[i * 3 + 1] = image.url

		if alt := image.alt {
			if alt == '' {
				params[i * 3 + 2] = firebird.Null{}
			} else {
				params[i * 3 + 2] = alt
			}
		} else {
			params[i * 3 + 2] = firebird.Null{}
		}

		// compute number of tranlsations to insert
		if translations := image.translations {
			translation_n += translations.len
		}
	}

	mut query := 'INSERT INTO image (id, url, alt) ${get_merge_source(src)}'
	tx.execute(query, ...params)!

	// insert translations if any
	if translation_n > 0 {
		src = []string{len: translation_n}
		params = []firebird.Value{len: translation_n * 3, init: firebird.Null{}}
		mut current_translation_i := i32(0)
		for i := 0; i < images.len; i++ {
			image := images[i]
			if translations := images[i].translations {
				for k := 0; k < translations.len; k++ {
					translation := translations[k]
					src[current_translation_i] = 'SELECT
						CAST(? AS BINARY(16)),
						CAST(? AS BINARY(16)),
						CAST(? AS VARCHAR(191))
						FROM RDB\$DATABASE'

					params[current_translation_i * 3] = image.id.bytes()
					params[current_translation_i * 3 + 1] = translation.locale_id.bytes()
					params[current_translation_i * 3 + 2] = translation.alt
					current_translation_i++
				}
			}
		}

		query = 'INSERT INTO image_translations (image_id, locale_id, alt) ${get_merge_source(src)}'
		tx.execute(query, ...params)!
	}

	// insert product_image relation
	src = []string{len: images.len}
	params = []firebird.Value{len: images.len * 3, init: firebird.Null{}}
	for i := 0; i < images.len; i++ {
		image := images[i]
		src[i] = 'SELECT
			CAST(? AS BINARY(16)),
			CAST(? AS BINARY(16)),
			CAST(? AS INTEGER)
			FROM RDB\$DATABASE'

		params[i * 3] = product_id.bytes()
		params[i * 3 + 1] = image.id.bytes()
		params[i * 3 + 2] = image.image_rank
	}

	query = 'INSERT INTO product_image (product_id, image_id, image_rank) ${get_merge_source(src)}'
	tx.execute(query, ...params)!
}

// TODO split operations
pub fn product_image_update(mut tx firebird.Transaction, product_id ID, images []ProductImageCreateParams) ! {
	mut image_ids := []ID{len: images.len}
	mut n_translations := 0
	mut src := []string{len: images.len}
	mut params := []firebird.Value{len: images.len * 3, init: firebird.Null{}}

	for i := 0; i < images.len; i++ {
		image := images[i]
		src[i] = 'SELECT
			CAST(? AS BINARY(16)) AS id,
			CAST(? AS BLOB SUB_TYPE TEXT) AS url,
			CAST(? AS VARCHAR(191)) AS alt
			FROM RDB\$DATABASE'

		params[i * 3] = image.id.bytes()
		params[i * 3 + 1] = image.url

		if alt := image.alt {
			if alt == '' {
				params[i * 3 + 2] = firebird.Null{}
			} else {
				params[i * 3 + 2] = alt
			}
		} else {
			params[i * 3 + 2] = firebird.Null{}
		}

		image_ids[i] = image.id
		if translations := image.translations {
			n_translations += translations.len
		}
	}

	mut query := 'MERGE INTO image t
		USING (${get_merge_source(src)}) s
		ON (t.id = s.id)
		WHEN MATCHED THEN
			UPDATE SET alt = s.alt
		WHEN NOT MATCHED THEN
		INSERT (id, url, alt)
		VALUES (s.id, s.url, s.alt)'

	tx.execute(query, ...params)!

	// kill orphans
	params = []firebird.Value{len: image_ids.len + 1, init: firebird.Null{}}
	params[0] = product_id.bytes()
	for i := 0; i < image_ids.len; i++ {
		params[i + 1] = image_ids[i].bytes()
	}

	query = 'DELETE FROM image i
		WHERE EXISTS (
			SELECT 1 FROM product_image pi
			WHERE pi.product_id = ?
			AND pi.image_id = i.id
		)
		AND i.id NOT IN (${get_placeholders(image_ids)})'
	tx.execute(query, ...params)!

	// handle relations
	query = 'DELETE FROM product_image WHERE product_id = ?'
	tx.execute(query, product_id.bytes())!

	src = []string{len: images.len}
	params = []firebird.Value{len: images.len * 3, init: firebird.Null{}}
	for i := 0; i < images.len; i++ {
		image := images[i]
		src[i] = 'SELECT
			CAST(? AS BINARY(16)) AS product_id,
			CAST(? AS BINARY(16)) AS image_id,
			CAST(? AS INTEGER) AS image_rank
			FROM RDB\$DATABASE'

		params[i * 3] = product_id.bytes()
		params[i * 3 + 1] = image.id.bytes()
		params[i * 3 + 2] = image.image_rank
	}

	query = 'INSERT INTO product_image (product_id, image_id, image_rank) ${get_merge_source(src)}'
	tx.execute(query, ...params)!

	// handle translations
	query = 'DELETE FROM image_translations WHERE image_id IN (${get_placeholders(image_ids)})'
	tx.execute(query, ...ids_bytes(image_ids))!

	if n_translations == 0 {
		return
	}

	src = []string{len: n_translations}
	params = []firebird.Value{len: n_translations * 3, init: firebird.Null{}}
	mut current_translation := 0
	for i := 0; i < images.len; i++ {
		image := images[i]
		if translations := image.translations {
			for t := 0; t < translations.len; t++ {
				translation := translations[t]
				src[current_translation] = 'SELECT
					CAST(? AS BINARY(16)) AS image_id,
					CAST(? AS BINARY(16)) AS locale_id,
					CAST(? AS VARCHAR(191)) AS alt
					FROM RDB\$DATABASE'
				params[current_translation * 3] = image.id.bytes()
				params[current_translation * 3 + 1] = translation.locale_id.bytes()
				params[current_translation * 3 + 2] = translation.alt
				current_translation++
			}
		}
	}

	query = 'INSERT INTO image_translations (image_id, locale_id, alt) ${get_merge_source(src)}'
	tx.execute(query, ...params)!
}
