module record

// import arrays
import einar_hjortdal.firebird
import arrays

pub struct ImageTranslation {
pub:
	image_id  ID
	locale_id ID
	alt       string
}

pub fn (it ImageTranslation) locale_id() ID {
	return it.locale_id
}

pub fn image_translation_retrieve(mut tx firebird.ClientTransaction, image_ids []ID) ![]ImageTranslation {
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

pub struct ImageTranslationCreateParams {
pub:
	image_id  ID
	locale_id ID
	alt       string
}

pub fn image_translation_create(mut tx firebird.ClientTransaction,
	translations []ImageTranslationCreateParams) ! {
	if translations.len == 0 {
		return
	}

	mut src := []string{len: 0, cap: translations.len}
	mut params := []firebird.Value{len: 0, cap: 3 * translations.len, init: firebird.Null{}}
	for _, translation in translations {
		image_id := translation.image_id
		src << 'SELECT
			CAST(? AS BINARY(16)),
			CAST(? AS BINARY(16)),
			CAST(? AS VARCHAR(191))
			FROM RDB\$DATABASE'

		params << image_id.bytes()
		params << translation.locale_id.bytes()
		params << translation.alt.clone()
	}

	tx.execute('INSERT INTO image_translations image_id, locale_id, alt ${get_merge_source(src)}',
		...params)!
}

pub fn image_translation_delete(mut tx firebird.ClientTransaction, image_ids []ID) ! {
	if image_ids.len == 0 {
		return
	}

	tx.execute('DELETE FROM image_translations WHERE image_id IN (${get_placeholders(image_ids)})',
		...ids_bytes(image_ids))!
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

pub fn image_retrieve(mut tx firebird.ClientTransaction, image_ids []ID) !Image {
	data := tx.execute('SELECT id, url, alt FROM image WHERE id IN (${get_placeholders(image_ids)})',
		ids_bytes(image_ids))!

	rows := data.rows()
	if rows.len == 0 {
		return error('not found')
	}

	v := rows[0].values()
	image_id_bin, _ := v[0].get_array_u8()!
	url, _ := v[1].get_string()!
	alt := v[2].get_null_string()!

	image_id := id_from_bytes(image_id_bin)!

	return Image{
		id:  image_id
		url: url
		alt: alt.none_value()
	}
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

pub struct ProductImageRetrieveParams {
pub:
	image_ids   ?[]ID
	product_ids ?[]ID
}

fn product_image_retrieve_condition(p ProductImageRetrieveParams) (string, []firebird.Value) {
	mut conditions := []string{len: 0, cap: 2}
	mut params := []firebird.Value{}
	if image_ids := p.image_ids {
		conditions << 'WHERE pi.image_id IN (${get_placeholders(image_ids)})'
		params << ids_bytes(image_ids)
	}

	if product_ids := p.product_ids {
		conditions << 'WHERE pi.product_id IN (${get_placeholders(product_ids)})'
		params << ids_bytes(product_ids)
	}

	return get_conditions(conditions), params
}

// TODO validate params
pub fn product_image_retrieve(mut tx firebird.ClientTransaction, p ProductImageRetrieveParams) ![]ProductImage {
	conditions, params := product_image_retrieve_condition(p)
	mut query := 'SELECT
		i.id,
		i.url,
		i.alt,
		pi.image_rank,
		pi.product_id
		FROM image i
		LEFT JOIN product_image pi
		ON i.id = pi.image_id
		${conditions}
		ORDER BY pi.image_rank'

	data := tx.execute(query, ...params)!

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

pub struct ImageCreateParams {
pub:
	id  ID
	url string
	alt ?string
}

pub fn image_create(mut tx firebird.ClientTransaction, images []ImageCreateParams) ! {
	mut src := []string{len: 0, cap: images.len}
	n_params := 3
	mut params := []firebird.Value{len: 0, cap: n_params * images.len, init: firebird.Null{}}
	for _, image in images {
		src << 'SELECT
			CAST(? AS BINARY(16)),
			CAST(? AS BLOB SUB_TYPE TEXT),
			CAST(? AS VARCHAR(191))
			FROM RDB\$DATABASE'

		params << image.id.bytes()
		params << image.url.clone()

		if alt := image.alt {
			if alt == '' {
				params << firebird.Null{}
			} else {
				params << alt
			}
		} else {
			params << firebird.Null{}
		}
	}

	query := 'INSERT INTO image (id, url, alt) ${get_merge_source(src)}'
	tx.execute(query, ...params)!
}

pub struct ImageUpdateParams {
pub:
	id  ID
	url ?string
	alt ?string
}

// updates one image
pub fn image_update(mut tx firebird.ClientTransaction, image ImageUpdateParams) ! {
	mut columns := []string{len: 0, cap: 2}
	mut params := []firebird.Value{len: 0, cap: 3, init: firebird.Null{}}

	if url := image.url {
		columns << 'url'
		params << url
	}

	if alt := image.alt {
		columns << 'alt'
		params << alt
	}

	params << image.id.bytes()

	tx.execute('UPDATE image SET ${get_set_columns(columns)} WHERE id = ?', ...params)!
}

pub fn image_delete(mut tx firebird.ClientTransaction, image_ids []ID) ! {
	tx.execute('DELETE FROM image WHERE id IN (${get_placeholders(image_ids)})',
		ids_bytes(image_ids))!
}

pub struct ProductImageCreateParams {
pub:
	product_id ID
	image_id   ID
	image_rank ?i32
}

// For use during product creation.
// To guarantee no duplicate image_rank, always provide image_rank when preparing parameters.
pub fn product_image_create(mut tx firebird.ClientTransaction, p []ProductImageCreateParams) ! {
	mut src := []string{len: 0, cap: p.len}
	n_params := 3
	mut params := []firebird.Value{len: 0, cap: n_params * p.len, init: firebird.Null{}}
	for _, relation in p {
		src << 'SELECT
			CAST(? AS BINARY(16)),
			CAST(? AS BINARY(16)),
			CAST(? AS INTEGER)
			FROM RDB\$DATABASE'

		params << relation.product_id.bytes()
		params << relation.image_id.bytes()

		if image_rank := relation.image_rank {
			params << image_rank
		} else {
			params << firebird.Null{}
		}
	}

	query := 'INSERT INTO product_image (product_id, image_id, image_rank) ${get_merge_source(src)}'

	tx.execute(query, ...params)!
}

pub fn product_image_create_one(mut tx firebird.ClientTransaction, product_id ID, image_id ID) ! {
	query := 'INSERT INTO product_image (product_id, image_id, image_rank)
		SELECT
			CAST(? AS BINARY(16)),
			CAST(? AS BINARY(16)),
			(
				SELECT COALESCE(MAX(image_rank), 0) + 1
				FROM product_image
				WHERE product_id = ?
			)
			FROM RDB\$DATABASE'
	tx.execute(query, product_id.bytes(), image_id.bytes(), product_id.bytes())!
}

pub struct ProductImageUpdateParams {
pub:
	id         ID
	url        string
	image_rank i32
	alt        ?string
}

pub fn product_image_update(mut tx firebird.ClientTransaction, product_id ID, images []ProductImageUpdateParams) ! {
	if images.len == 0 {
		tx.execute('DELETE FROM image i WHERE EXISTS
			(
				SELECT 1 FROM product_image pi
				WHERE pi.product_id = ?
				AND pi.image_id = i.id
			)',
			product_id.bytes())!
		return
	}

	mut src := []string{len: 0, cap: images.len}
	mut params := []firebird.Value{len: 0, cap: 3 * images.len, init: firebird.Null{}}
	mut image_ids := []ID{len: 0, cap: images.len}
	for _, image in images {
		src << 'SELECT
			CAST(? AS BINARY(16)),
			CAST(? AS BLOB SUB_TYPE TEXT),
			CAST(? AS VARCHAR(191))
			FROM RDB\$DATABASE'

		params << image.id.bytes()
		params << image.url.clone()

		if alt := image.alt {
			if alt == '' {
				params << firebird.Null{}
			} else {
				params << alt
			}
		} else {
			params << firebird.Null{}
		}

		image_ids << image.id
	}

	tx.execute('MERGE INTO image t
		USING (${get_merge_source(src)}) s (id, url, alt)
		ON t.id = s.id
		WHEN MATCHED THEN
			UPDATE SET t.url = s.url, t.alt = s.alt
		WHEN NOT MATCHED THEN
			INSERT (id, url, alt)
			VALUES (s.id, s.url, s.alt)',
		...params)!

	tx.execute('DELETE FROM image i WHERE EXISTS
			(
				SELECT 1 FROM product_image pi
				WHERE pi.product_id = ?
				AND pi.image_id = i.id
			)
			AND i.id NOT IN (${get_placeholders(image_ids)})', ...ids_bytes(arrays.concat([
		product_id,
	], ...image_ids)))!

	src = []string{len: 0, cap: images.len}
	params = []firebird.Value{len: 0, cap: 3 * images.len + 1, init: firebird.Null{}}

	for _, image in images {
		src << 'SELECT
			CAST(? AS BINARY(16)),
			CAST(? AS BLOB SUB_TYPE TEXT),
			CAST(? AS INTEGER)
			FROM RDB\$DATABASE'

		params << product_id.bytes()
		params << image.id.bytes()
		params << i32(image.image_rank)
	}

	params << product_id.bytes()

	tx.execute('MERGE INTO product_image t
		USING (${get_merge_source(src)}) s (product_id, image_id, image_rank)
		ON t.product_id = s.product_id AND t.image_id = s.image_id
		WHEN MATCHED THEN
			UPDATE SET t.image_rank = s.image_rank
		WHEN NOT MATCHED THEN
			INSERT (product_id, image_id, image_rank)
			VALUES (s.product_id, s.image_id, s.image_rank)',
		...params)!
}
