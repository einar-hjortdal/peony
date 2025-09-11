module peony

import arrays
import einar_hjortdal.firebird

const product_status_draft = 'draft'
const product_status_proposed = 'proposed'
const product_status_published = 'published'
const product_status_rejected = 'rejected'

struct Product {
	id           string
	id_bin       []u8
	created_at   firebird.DateTime
	updated_at   firebird.DateTime
	deleted_at   firebird.NullDateTime
	handle       string
	is_giftcard  bool
	status       string
	thumbnail    firebird.NullString
	type_id_bin  firebird.NullArrayU8
	discountable bool
	metadata     firebird.NullString
	title        firebird.NullString
	subtitle     firebird.NullString
	description  firebird.NullString
mut:
	categories     []ProductCategory
	images         []ProductImage
	options        []ProductOption
	sales_channels []SalesChannel
	translations   []ProductTranslation
	variants       []ProductVariant
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

	if ph.title.is_set {
		conditions = arrays.concat(conditions, "EXISTS (
			SELECT 1 FROM product_translations ptr
			WHERE ptr.product_id = p.id
				AND UPPER(ptr.title) LIKE UPPER('%' || ? || '%')
			)")
		params = arrays.concat(params, ph.title.v)
	}

	if ph.description.is_set {
		conditions = arrays.concat(conditions, "EXISTS (
			SELECT 1 FROM product_translations ptr
			WHERE ptr.product_id = p.id
				AND UPPER(ptr.description) LIKE UPPER('%' || ? || '%')
			)")
		params = arrays.concat(params, ph.description.v)
	}

	if ph.category_ids.is_set {
		conditions = arrays.concat(conditions, 'EXISTS (
			SELECT 1 FROM product_category_product pcp
			WHERE pcp.product_id = p.id
				AND pcp.product_category_id IN (${get_placeholders(ph.category_ids_bin)})
			')
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
		params = arrays.concat(params, ...ph.sales_channel_ids_bin)
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
	mut params := []firebird.Value{}

	// left join params
	if ph.locale_id.is_set {
		params = arrays.concat(params, ph.locale_id_bin, ph.locale_id_bin)
	} else {
		params = arrays.concat(params, firebird.Null{}, firebird.Null{})
	}

	conditions, condition_params := model_product_retrieve_conditions(ph)
	params = arrays.append(params, condition_params)

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
		p.thumbnail,
		p.type_id,
		p.discountable,
		p.metadata,
		COALESCE(pt_requested.title, pt_default.title) AS title,
		COALESCE(pt_requested.subtitle, pt_default.subtitle) AS subtitle,
		COALESCE(pt_requested.description, pt_default.description) AS description
		FROM product p
		LEFT JOIN product_translations pt_default
			ON pt_default.product_id = p.id
			AND pt_default.locale_id = (
				SELECT default_locale_id FROM store
			)
		LEFT JOIN product_translations pt_requested
			ON CAST(? AS BINARY(16)) IS NOT NULL
			AND pt_requested.product_id = p.id
			AND pt_requested.locale_id = ?
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
		thumbnail := v[7].get_null_string()!
		type_id_bin := v[8].get_null_array_u8()!
		discountable, _ := v[9].get_bool()!
		metadata := v[10].get_null_string()!
		title := v[11].get_null_string()!
		subtitle := v[12].get_null_string()!
		description := v[13].get_null_string()!

		id := id_bin_to_string(id_bin)!

		products[i] = Product{
			id:           id
			id_bin:       id_bin
			created_at:   created_at
			updated_at:   updated_at
			deleted_at:   deleted_at
			handle:       handle
			is_giftcard:  is_giftcard
			status:       status
			thumbnail:    thumbnail
			type_id_bin:  type_id_bin
			discountable: discountable
			metadata:     metadata
			title:        title
			subtitle:     subtitle
			description:  description
		}
	}
	return products
}

fn model_product_create(mut tx firebird.Transaction, product_id string, product_id_bin []u8, ph ProductRequestHygienised) ! {
	mut c := ['id']
	mut params := [firebird.Value(product_id_bin)]

	c = arrays.concat(c, 'handle')
	if handle := ph.handle {
		params = arrays.concat(params, handle)
	} else {
		params = arrays.concat(params, product_id)
	}

	if is_giftcard := ph.is_giftcard {
		c = arrays.concat(c, 'is_giftcard')
		params = arrays.concat(params, is_giftcard)
	}

	if status := ph.status {
		c = arrays.concat(c, 'status')
		params = arrays.concat(params, status)
	}

	if thumbnail := ph.thumbnail {
		c = arrays.concat(c, 'thumbnail')
		params = arrays.concat(params, thumbnail)
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

fn model_product_update(mut tx firebird.Transaction, product_id_bin []u8, ph ProductRequestHygienised) ! {
	mut c := []string{}
	mut params := []firebird.Value{}

	if handle := ph.handle {
		c = arrays.concat(c, 'handle')
		params = arrays.concat(params, handle)
	}

	if is_giftcard := ph.is_giftcard {
		c = arrays.concat(c, 'is_giftcard')
		params = arrays.concat(params, is_giftcard)
	}

	if status := ph.status {
		c = arrays.concat(c, 'status')
		params = arrays.concat(params, status)
	}

	if thumbnail := ph.thumbnail {
		c = arrays.concat(c, 'thumbnail')
		params = arrays.concat(params, thumbnail)
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
