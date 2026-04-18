module peony

import arrays
import einar_hjortdal.firebird

pub const product_status_draft = 'draft'
pub const product_status_proposed = 'proposed'
pub const product_status_published = 'published'
pub const product_status_rejected = 'rejected'

struct ProductTranslation {
	product_id     string
	product_id_bin []u8
	locale_id      string
	locale_id_bin  []u8
	title          string
	subtitle       string
	description    string
}

fn model_product_translations_retrieve(mut tx firebird.Transaction, product_ids_bin [][]u8) ![]ProductTranslation {
	data := tx.execute('SELECT
		product_id,
		locale_id,
		title,
		subtitle,
		description
		FROM product_translations
		WHERE product_id IN (${get_placeholders(product_ids_bin)})',
		...product_ids_bin)!

	rows := data.rows()

	mut translations := []ProductTranslation{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()

		product_id_bin, _ := v[0].get_array_u8()!
		locale_id_bin, _ := v[1].get_array_u8()!
		title, _ := v[2].get_string()!
		subtitle, _ := v[3].get_string()!
		description, _ := v[4].get_string()!

		product_id := id_bin_to_string(product_id_bin)!
		locale_id := id_bin_to_string(locale_id_bin)!

		translations[i] = ProductTranslation{
			product_id:     product_id
			product_id_bin: product_id_bin
			locale_id:      locale_id
			locale_id_bin:  locale_id_bin
			title:          title
			subtitle:       subtitle
			description:    description
		}
	}

	return translations
}

fn model_product_translations_delete(mut tx firebird.Transaction, product_id_bin []u8) ! {
	tx.execute('DELETE FROM product_translations WHERE product_id = ?', product_id_bin)!
}

fn model_product_translations_create(mut tx firebird.Transaction, product_id_bin []u8, ph []ProductTranslationRequestHygienised) ! {
	mut src := []string{len: ph.len}
	mut params := []firebird.Value{len: ph.len * 5, init: firebird.Null{}}
	for i := 0; i < ph.len; i++ {
		t := ph[i]
		src[i] = 'SELECT
			CAST(? AS BINARY(16)) AS product_id,
			CAST(? AS BINARY(16)) AS locale_id,
			CAST(? AS VARCHAR(63)) AS title,
			CAST(? AS VARCHAR(191)) AS subtitle,
			CAST(? AS BLOB SUB_TYPE TEXT) AS description
			FROM RDB\$DATABASE'

		params[i * 5] = product_id_bin
		params[i * 5 + 1] = t.locale_id_bin

		if title := t.title {
			params[i * 5 + 2] = title
		} else {
			params[i * 5 + 2] = firebird.Null{}
		}

		if subtitle := t.subtitle {
			params[i * 5 + 3] = subtitle
		} else {
			params[i * 5 + 3] = firebird.Null{}
		}

		if description := t.description {
			params[i * 5 + 4] = description
		} else {
			params[i * 5 + 4] = firebird.Null{}
		}
	}

	tx.execute('INSERT INTO product_translations (product_id, locale_id, title, subtitle, description)
		${get_merge_source(src)}',
		...params)!
}

struct Product {
	id               string
	id_bin           []u8
	created_at       firebird.DateTime
	updated_at       firebird.DateTime
	deleted_at       firebird.NullDateTime
	handle           string
	title            string
	subtitle         firebird.NullString
	description      firebird.NullString
	is_giftcard      bool
	status           string
	type_id_bin      []u8
	type_id          string
	thumbnail_id_bin []u8
	thumbnail_id     string
	discountable     bool
	metadata         firebird.NullString
mut:
	seo                    ProductSEO
	images                 []ProductImage
	options                []ProductOption
	translations           []ProductTranslation
	variants               []ProductVariant
	category_ids           []string
	category_ids_bin       [][]u8
	sales_channels_ids     []string
	sales_channels_ids_bin [][]u8
	// tags         []Tag
}

struct ProductRetrieveParams {
	ids              ?[]ID
	handle           ?string
	is_giftcard      ?bool
	status           ?string
	category_ids     ?[]ID
	sales_channel_id ?ID
	with_deleted     bool
	offset           i32
	fetch            i32
	order            string
}

fn model_product_retrieve_conditions(p ProductRetrieveParams) (string, []firebird.Value) {
	mut conditions := []string{}
	mut params := []firebird.Value{}

	if ids := p.ids {
		conditions = arrays.concat(conditions, 'id IN (${get_placeholders(ids)})')
		params = arrays.concat(params, ...ids_bytes(ids))
	}

	if handle := p.handle {
		conditions = arrays.concat(conditions, 'p.handle = ?')
		params = arrays.concat(params, handle)
	}

	if is_giftcard := p.is_giftcard {
		conditions = arrays.concat(conditions, 'p.is_giftcard = ?')
		params = arrays.concat(params, is_giftcard)
	}

	if status := p.status {
		conditions = arrays.concat(conditions, 'p.status = ?')
		params = arrays.concat(params, status)
	}

	//	if ph.type_ids.is_set {
	//		conditions = arrays.concat(conditions, 'p.type_id IN ${get_placeholders(ph.type_ids_bin)}')
	//		params = arrays.concat(params, ...ph.type_ids_bin)
	//	}
	//
	//	if ph.tag_ids.is_set {
	//		conditions = arrays.concat(conditions, 'EXISTS (
	//			SELECT 1 FROM product_tag_product pt
	//			WHERE pt.product_id = p.id
	//				AND pt.tag_id IN (${get_placeholders(ph.tag_ids_bin)})
	//			)')
	//		params = arrays.concat(params, ...ph.tag_ids_bin)
	//	}

	if category_ids := p.category_ids {
		conditions = arrays.concat(conditions, 'EXISTS (
			SELECT 1 FROM category_product cp
			WHERE cp.product_id = p.id
				AND cp.category_id IN (${get_placeholders(category_ids)})
			)')
		params = arrays.concat(params, ...ids_bytes(category_ids))
	}

	// TODO price lists
	// if ph.price_list_ids.is_set {
	// 	conditions = arrays.concat(conditions, 'EXISTS (
	// 		SELECT 1 FROM
	// 		WHERE
	// 			AND ma.price_list_id IN (${get_placeholders(ph.price_list_ids_bin)})
	// 		)')
	// 	params = arrays.concat(params, ...ph.price_list_ids_bin)
	// }

	if sales_channel_id := p.sales_channel_id {
		conditions = arrays.concat(conditions, 'EXISTS (
			SELECT 1 FROM product_sales_channel psc
			WHERE psc.product_id = p.id
				AND sales_channel_id = ?
			)')
		params = arrays.concat(params, sales_channel_id)
	}

	if !p.with_deleted {
		conditions = arrays.concat(conditions, 'p.deleted_at is NULL')
	}

	return get_where_conditions(conditions), params
}

fn model_product_retrieve_count(mut tx firebird.Transaction, p ProductRetrieveParams) !i64 {
	conditions, params := model_product_retrieve_conditions(p)
	data := tx.execute('SELECT COUNT(*) FROM product p ${conditions}', ...params)!
	rows := data.rows()
	values := rows[0].values() // should always return one row
	count, _ := values[0].get_i64()! // should always return one column
	return count
}

fn model_product_retrieve(mut tx firebird.Transaction, p ProductRetrieveParams) ![]Product {
	conditions, mut params := model_product_retrieve_conditions(p)

	mut sorting := 'ORDER BY created_at ${p.order}
		OFFSET ? ROWS
		FETCH NEXT ? ROWS ONLY'
	params = arrays.concat(params, p.offset, p.fetch)

	data := tx.execute('SELECT
		p.id,
		p.created_at,
		p.updated_at,
		p.deleted_at,
		p.handle,
		p.is_giftcard,
		p.status,
		p.thumbnail_id,
		p.type_id,
		p.discountable,
		p.metadata,
		p.title,
		p.subtitle,
		p.description
		FROM product p
		${conditions}
		${sorting}',
		...params)!

	rows := data.rows()
	mut products := []Product{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()

		id_bin, _ := v[0].get_array_u8()!
		created_at, _ := v[1].get_date_time()!
		updated_at, _ := v[2].get_date_time()!
		deleted_at := v[3].get_null_date_time()!
		handle, _ := v[4].get_string()!
		is_giftcard, _ := v[5].get_bool()!
		status, _ := v[6].get_string()!
		thumbnail_id_bin, _ := v[7].get_array_u8()!
		type_id_bin, _ := v[8].get_array_u8()!
		discountable, _ := v[9].get_bool()!
		metadata := v[10].get_null_string()!
		title, _ := v[11].get_string()!
		subtitle := v[12].get_null_string()!
		description := v[13].get_null_string()!

		id := id_bin_to_string(id_bin)!

		mut thumbnail_id := ''
		if thumbnail_id_bin.len > 0 {
			thumbnail_id = id_bin_to_string(thumbnail_id_bin)!
		}

		mut type_id := ''
		if type_id_bin.len > 0 {
			type_id = id_bin_to_string(type_id_bin)!
		}

		products[i] = Product{
			id:               id
			id_bin:           id_bin
			created_at:       created_at
			updated_at:       updated_at
			deleted_at:       deleted_at
			handle:           handle
			is_giftcard:      is_giftcard
			status:           status
			thumbnail_id_bin: thumbnail_id_bin
			thumbnail_id:     thumbnail_id
			type_id_bin:      type_id_bin
			type_id:          type_id
			discountable:     discountable
			metadata:         metadata
			title:            title
			subtitle:         subtitle
			description:      description
		}
	}
	return products
}

struct ProductCreateParams {
	product_id     string
	product_id_bin []u8
	title          string
	subtitle       string
	description    string
	handle         string
	is_giftcard    ?bool
	status         ?string
	type_id        string
	type_id_bin    []u8
	discountable   ?bool
	metadata       string
}

fn model_product_create(mut tx firebird.Transaction, p ProductCreateParams) ! {
	if p.product_id == '' || p.product_id_bin.len == 0 || p.title == '' || p.handle == '' {
		return new_error_internal('Missing required data in ProductCreateParams',
			'product_id: ${p.product_id}, product_id_bin.len: ${p.product_id_bin.len}, title: ${p.title}, handle: ${p.handle}')
	}

	mut c := ['id', 'title', 'handle']
	mut params := [firebird.Value(p.product_id_bin), p.title, p.handle]

	if p.subtitle != '' {
		c = arrays.concat(c, 'subtitle')
		params = arrays.concat(params, p.subtitle)
	}

	if p.description != '' {
		c = arrays.concat(c, 'description')
		params = arrays.concat(params, p.description)
	}

	if p.is_giftcard != none {
		c = arrays.concat(c, 'is_giftcard')
		params = arrays.concat(params, p.is_giftcard)
	}

	if p.status != none {
		c = arrays.concat(c, 'status')
		params = arrays.concat(params, p.status)
	}

	if p.type_id != '' {
		c = arrays.concat(c, 'type_id')
		params = arrays.concat(params, p.type_id_bin)
	}

	if p.discountable != none {
		c = arrays.concat(c, 'discountable')
		params = arrays.concat(params, p.discountable)
	}

	if p.metadata != '' {
		c = arrays.concat(c, 'metadata')
		params = arrays.concat(params, p.metadata)
	}

	query := 'INSERT INTO product (${get_columns(c)}) VALUES (${get_placeholders(c)})'
	tx.execute(query, ...params)!
}

struct ProductUpdateParams {
	product_id     string
	product_id_bin []u8
	title          string
	subtitle       string
	description    string
	handle         string
	is_giftcard    bool
	status         string
	type_id        string
	type_id_bin    []u8
	discountable   bool
	metadata       string
}

fn model_product_update(mut tx firebird.Transaction, p ProductUpdateParams) ! {
	if p.product_id == '' {
		return error('Invalid product_id in ProductCreateParams: `${p.product_id}`')
	}

	if p.product_id_bin.len == 0 {
		return error('Invalid product_id_bin in ProductCreateParams: `${p.product_id_bin.len}`')
	}

	if p.handle == '' {
		return error('Invalid handle in ProductCreateParams: `${p.handle}`')
	}

	if p.title == '' {
		return error('Invalid title in ProductCreateParams: `${p.title}`')
	}

	columns := [
		'handle',
		'title',
		'subtitle',
		'description',
		'is_giftcard',
		'status',
		'type_id',
		'discountable',
		'metadata',
	]
	query := 'UPDATE product SET ${get_set_columns_with_updated_at(columns)} WHERE product.id = ?'

	mut params := []firebird.Value{len: 10, init: firebird.Null{}}

	params[0] = p.handle
	params[1] = p.title
	params[2] = p.subtitle
	params[3] = p.description
	params[4] = p.is_giftcard
	params[5] = p.status

	if p.type_id_bin.len > 0 {
		params[6] = p.type_id_bin
	}

	params[7] = p.discountable
	params[8] = p.metadata
	params[9] = p.product_id_bin

	tx.execute(query, ...params)!
}

fn model_product_delete(mut tx firebird.Transaction, product_id_bin []u8) ! {
	tx.execute('UPDATE product SET deleted_at = CURRENT_TIMESTAMP WHERE id = ?', product_id_bin)!
}

fn model_product_thumbnail_update(mut tx firebird.Transaction, product_id_bin []u8, image_rank i32) ! {
	tx.execute('UPDATE product p
		SET 
			updated_at = CURRENT_TIMESTAMP,
			p.thumbnail_id = (
				SELECT pi.image_id
				FROM product_image pi
				WHERE pi.product_id = p.id
				AND pi.image_rank = ?
			)
		WHERE p.id = ?',
		image_rank, product_id_bin)!
}

fn model_product_thumbnail_delete(mut tx firebird.Transaction, product_id_bin []u8) ! {
	tx.execute('UPDATE product SET thumbnail_id = NULL WHERE id = ?', product_id_bin)!
}

