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
		...workaround_24757(product_ids_bin))!

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

fn model_product_retrieve_conditions(ph RetrieveProductParamsHygienised) (string, []firebird.Value) {
	mut conditions := []string{}
	mut params := []firebird.Value{}

	if !ph.with_deleted.is_set || (ph.with_deleted.is_set && !ph.with_deleted.v) {
		conditions = arrays.concat(conditions, 'p.deleted_at IS NULL')
	}

	if ph.ids.is_set {
		conditions = arrays.concat(conditions, 'p.id IN (${get_placeholders(ph.ids_bin)})')
		params = arrays.concat(params, ...workaround_24757(ph.ids_bin))
	}

	if ph.handle.is_set {
		conditions = arrays.concat(conditions, 'p.handle = ?')
		params = arrays.concat(params, ph.handle.v)
	}

	if ph.is_giftcard.is_set {
		conditions = arrays.concat(conditions, 'p.is_giftcard = ?')
		params = arrays.concat(params, ph.is_giftcard.v)
	}

	if ph.status.is_set {
		conditions = arrays.concat(conditions, 'p.status = ?')
		params = arrays.concat(params, ph.status.v)
	}

	if ph.collection_ids.is_set {
		// TODO
		// conditions = arrays.concat(conditions, 'p.collection_id IN (${get_placeholders(ph.collection_ids_bin)})')
		// params = arrays.concat(params, ...workaround_24757(ph.collection_ids_bin))
	}

	if ph.type_ids.is_set {
		conditions = arrays.concat(conditions, 'p.type_id IN ${get_placeholders(ph.type_ids_bin)}')
		params = arrays.concat(params, ...workaround_24757(ph.type_ids_bin))
	}

	if ph.tag_ids.is_set {
		conditions = arrays.concat(conditions, 'EXISTS (
			SELECT 1 FROM product_tag_product pt
			WHERE pt.product_id = p.id
				AND pt.tag_id IN (${get_placeholders(ph.tag_ids_bin)})
			)')
		params = arrays.concat(params, ...ph.tag_ids_bin)
	}

	if ph.category_ids.is_set {
		conditions = arrays.concat(conditions, 'EXISTS (
			SELECT 1 FROM category_product cp
			WHERE cp.product_id = p.id
				AND cp.category_id IN (${get_placeholders(ph.category_ids_bin)})
			)')
		params = arrays.concat(params, ...workaround_24757(ph.category_ids_bin))
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

	if ph.sales_channel_ids.is_set {
		conditions = arrays.concat(conditions, 'EXISTS (
			SELECT 1 FROM product_sales_channel psc
			WHERE psc.product_id = p.id
				AND sales_channel_id IN (${get_placeholders(ph.sales_channel_ids_bin)})
			)')
		params = arrays.concat(params, ...workaround_24757(ph.sales_channel_ids_bin))
	}

	return get_where_conditions(conditions), params
}

fn model_product_retrieve_count(mut tx firebird.Transaction, ph RetrieveProductParamsHygienised) !i64 {
	conditions, params := model_product_retrieve_conditions(ph)
	data := tx.execute('SELECT COUNT(*) FROM product p ${conditions}', ...params)!
	rows := data.rows()
	values := rows[0].values() // should always return one row
	count, _ := values[0].get_i64()! // should always return one column
	return count
}

fn model_product_retrieve(mut tx firebird.Transaction, ph RetrieveProductParamsHygienised) ![]Product {
	conditions, mut params := model_product_retrieve_conditions(ph)

	mut sorting := 'ORDER BY created_at ${get_sorting_order(ph.order)}'

	if ph.offset.is_set {
		sorting = appendln(sorting, 'OFFSET ? ROWS')
		params = arrays.concat(params, ph.offset.v)
	}

	if ph.fetch.is_set {
		sorting = appendln(sorting, 'FETCH NEXT ? ROWS ONLY')
		params = arrays.concat(params, ph.fetch.v)
	}

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

fn model_product_create(mut tx firebird.Transaction, product_id string, product_id_bin []u8, ph ProductCreateRequestHygienised) ! {
	mut c := ['id', 'title', 'handle']
	mut params := [firebird.Value(product_id_bin), ph.title]

	if handle := ph.handle {
		params = arrays.concat(params, handle)
	} else {
		params = arrays.concat(params, product_id)
	}

	if subtitle := ph.subtitle {
		c = arrays.concat(c, 'subtitle')
		params = arrays.concat(params, subtitle)
	}

	if description := ph.description {
		c = arrays.concat(c, 'description')
		params = arrays.concat(params, description)
	}

	if is_giftcard := ph.is_giftcard {
		c = arrays.concat(c, 'is_giftcard')
		params = arrays.concat(params, is_giftcard)
	}

	if status := ph.status {
		c = arrays.concat(c, 'status')
		params = arrays.concat(params, status)
	}

	if _ := ph.type_id {
		c = arrays.concat(c, 'type_id')
		params = arrays.concat(params, ph.type_id_bin)
	}

	if discountable := ph.discountable {
		c = arrays.concat(c, 'discountable')
		params = arrays.concat(params, discountable)
	}

	if metadata := ph.metadata {
		c = arrays.concat(c, 'metadata')
		params = arrays.concat(params, metadata)
	}

	tx.execute('INSERT INTO product (${get_columns(c)}) VALUES (${get_placeholders(c)})',
		...params)!
}

fn model_product_update(mut tx firebird.Transaction, product_id_bin []u8, ph ProductUpdateRequestHygienised) ! {
	mut c := []string{}
	mut params := []firebird.Value{}

	if handle := ph.handle {
		c = arrays.concat(c, 'handle')
		params = arrays.concat(params, handle)
	}

	if title := ph.title {
		c = arrays.concat(c, 'title')
		params = arrays.concat(params, title)
	}

	if subtitle := ph.subtitle {
		c = arrays.concat(c, 'subtitle')
		params = arrays.concat(params, subtitle)
	}

	if description := ph.description {
		c = arrays.concat(c, 'description')
		params = arrays.concat(params, description)
	}

	if is_giftcard := ph.is_giftcard {
		c = arrays.concat(c, 'is_giftcard')
		params = arrays.concat(params, is_giftcard)
	}

	if status := ph.status {
		c = arrays.concat(c, 'status')
		params = arrays.concat(params, status)
	}

	if _ := ph.type_id {
		c = arrays.concat(c, 'type_id')
		params = arrays.concat(params, ph.type_id_bin)
	}

	if discountable := ph.discountable {
		c = arrays.concat(c, 'discountable')
		params = arrays.concat(params, discountable)
	}

	if metadata := ph.metadata {
		c = arrays.concat(c, 'metadata')
		params = arrays.concat(params, metadata)
	}

	query := 'UPDATE product SET ${get_set_columns_with_updated_at(c)} WHERE id = ?'
	params = arrays.concat(params, firebird.Value(product_id_bin))
	tx.execute(query, ...params)!
}

fn model_product_delete(mut tx firebird.Transaction, product_id_bin []u8) ! {
	tx.execute('UPDATE product SET deleted_at = CURRENT_TIMESTAMP WHERE id = ?', product_id_bin)!
}

fn model_product_thumbnail_update(mut tx firebird.Transaction, product_id_bin []u8, thumbnail_id_bin []u8) ! {
	tx.execute('UPDATE product SET thumbnail_id = ? WHERE id = ?', thumbnail_id_bin, product_id_bin)!
}

fn model_product_thumbnail_delete(mut tx firebird.Transaction, product_id_bin []u8) ! {
	tx.execute('UPDATE product SET thumbnail_id = NULL WHERE id = ?', product_id_bin)!
}
