module peony

import arrays
import einar_hjortdal.firebird
import einar_hjortdal.luuid

const product_status_draft = 'draft'
const product_status_proposed = 'proposed'
const product_status_published = 'published'
const product_status_rejected = 'rejected'

struct Product {
	id                string
	id_bin            []u8
	created_at        firebird.DateTime
	updated_at        firebird.DateTime
	deleted_at        firebird.NullDateTime
	handle            string
	is_giftcard       bool
	status            string
	thumbnail         firebird.NullString
	collection_id_bin firebird.NullArrayU8
	type_id_bin       firebird.NullArrayU8
	discountable      bool
	metadata          firebird.NullString
mut:
	images         []ProductImage
	options        []ProductOption
	variants       []ProductVariant
	translations   []ProductTranslation
	sales_channels []SalesChannel
	// tags         []Tag
}

fn do_retrieve_products__option_values(mut tx firebird.Transaction, po []ProductOption) ![]ProductOptionValue {
	mut option_ids_bin := [][]u8{}
	for i := 0; i < po.len; i++ {
		option_ids_bin = arrays.concat(option_ids_bin, po[i].id_bin)
	}

	option_values := model_product_option_values_retrieve(mut tx, option_ids_bin)!

	if option_values.len == 0 {
		return option_values
	}

	mut product_option_values_ids_bin := [][]u8{len: option_values.len}
	mut option_values_map := map[string]ProductOptionValue{}
	for i := 0; i < option_values.len; i++ {
		product_option_values_ids_bin[i] = option_values[i].id_bin
		option_value_id := option_values[i].id
		option_values_map[option_value_id] = option_values[i]
	}

	translations := model_product_option_value_translations_retrieve(mut tx, product_option_values_ids_bin)!
	for i := 0; i < translations.len; i++ {
		option_value_id := translations[i].product_option_value_id
		option_values_map[option_value_id].translations = arrays.concat(option_values_map[option_value_id].translations,
			translations[i])
	}

	mut result_option_values := []ProductOptionValue{len: option_values.len}
	for i := 0; i < option_values.len; i++ {
		option_value_id := option_values[i].id
		result_option_values[i] = option_values_map[option_value_id]
	}

	return result_option_values
}

fn model_product_retrieve_conditions(ph RetrieveProductParamsHygienised) (string, []firebird.Value) {
	mut conditions := []string{}
	mut params := []firebird.Value{}

	if !ph.with_deleted.is_set || (ph.with_deleted.is_set && !ph.with_deleted.v) {
		conditions = arrays.concat(conditions, 'deleted_at IS NULL')
	}

	if ph.ids.is_set {
		conditions = arrays.concat(conditions, 'id IN (${get_placeholders(ph.ids_bin)})')
		params = arrays.concat(params, ...workaround_24757(ph.ids_bin))
	}

	if ph.handle.is_set {
		conditions = arrays.concat(conditions, 'handle = ?')
		params = arrays.concat(params, ph.handle.v)
	}

	if ph.is_giftcard.is_set {
		conditions = arrays.concat(conditions, 'is_giftcard = ?')
		params = arrays.concat(params, ph.is_giftcard.v)
	}

	if ph.status.is_set {
		conditions = arrays.concat(conditions, 'status = ?')
		params = arrays.concat(params, ph.status.v)
	}

	if ph.collection_ids.is_set {
		conditions = arrays.concat(conditions, 'collection_id IN ${get_placeholders(ph.collection_ids_bin)}')
		params = arrays.concat(params, ...workaround_24757(ph.collection_ids_bin))
	}

	if ph.type_ids.is_set {
		conditions = arrays.concat(conditions, 'type_id IN ${get_placeholders(ph.type_ids_bin)}')
		params = arrays.concat(params, ...workaround_24757(ph.type_ids_bin))
	}

	if ph.tag_ids.is_set {
		conditions = arrays.concat(conditions, 'EXISTS (
			SELECT 1 FROM product_tag_product pt
			WHERE pt.product_id = product.id
				AND pt.tag_id IN (${get_placeholders(ph.tag_ids_bin)})
			)')
		params = arrays.concat(params, ...ph.tag_ids_bin)
	}

	if ph.title.is_set {
		conditions = arrays.concat(conditions, "EXISTS (
			SELECT 1 FROM product_translations ptr
			WHERE ptr.product_id = product.id
				AND UPPER(ptr.title) LIKE UPPER('%' || ? || '%')
			)")
		params = arrays.concat(params, ph.title.v)
	}

	if ph.description.is_set {
		conditions = arrays.concat(conditions, "EXISTS (
			SELECT 1 FROM product_translations ptr
			WHERE ptr.product_id = product.id
				AND UPPER(ptr.description) LIKE UPPER('%' || ? || '%')
			)")
		params = arrays.concat(params, ph.description.v)
	}

	if ph.category_ids.is_set {
		conditions = arrays.concat(conditions, 'EXISTS (
			SELECT 1 FROM product_category_product pcp
			WHERE pcp.product_id = product.id
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
			WHERE psc.product_id = product.id
				AND sales_channel_id IN (${get_placeholders(ph.sales_channel_ids_bin)})
			)')
		params = arrays.concat(params, ...ph.sales_channel_ids_bin)
	}

	return get_where_conditions(conditions), params
}

fn model_product_retrieve_count(mut tx firebird.Transaction, ph RetrieveProductParamsHygienised) !i64 {
	conditions, params := model_product_retrieve_conditions(ph)
	data := tx.execute('SELECT COUNT(*) FROM product ${conditions}', ...params)!
	rows := data.rows()
	values := rows[0].values() // should always return one row
	count, _ := values[0].get_i64()! // should always return one column
	return count
}

fn model_product_retrieve(mut tx firebird.Transaction, ph RetrieveProductParamsHygienised) ![]Product {
	conditions, mut params := model_product_retrieve_conditions(ph)

	mut sorting := ''
	sorting = appendln(sorting, 'ORDER BY created_at ${get_sorting_order(ph.order)}')

	if ph.offset.is_set {
		sorting = appendln(sorting, 'OFFSET ? ROWS')
		params = arrays.concat(params, ph.offset.v)
	}

	sorting = appendln(sorting, 'FETCH NEXT ? ROWS ONLY')
	params = arrays.concat(params, get_fetch_amount(ph.fetch))

	data := tx.execute('SELECT
		id,
		created_at,
		updated_at,
		deleted_at,
		handle,
		is_giftcard,
		status,
		thumbnail,
		collection_id,
		type_id,
		discountable,
		metadata
		FROM product
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
		collection_id_bin := v[8].get_null_array_u8()!
		type_id_bin := v[9].get_null_array_u8()!
		discountable, _ := v[10].get_bool()!
		metadata := v[11].get_null_string()!

		id := id_bin_to_string(id_bin)!

		products[i] = Product{
			id:                id
			id_bin:            id_bin
			created_at:        created_at
			updated_at:        updated_at
			deleted_at:        deleted_at
			handle:            handle
			is_giftcard:       is_giftcard
			status:            status
			thumbnail:         thumbnail
			collection_id_bin: collection_id_bin
			type_id_bin:       type_id_bin
			discountable:      discountable
			metadata:          metadata
		}
	}
	return products
}

fn (mut app App) do_create_product_translations(mut tx firebird.Transaction, product_id_bin []u8, translations []ProductTranslationRequest) ! {
	c := [
		'product_id',
		'locale_id',
		'title',
		'subtitle',
		'description',
	]
	mut stmt := tx.prepare('INSERT INTO product_translations (${get_columns(c)}) 
		VALUES (${get_placeholders(c)})')!

	p := [firebird.Value(product_id_bin)]
	for i := 0; i < translations.len; i++ {
		locale_id_bin := id_string_to_bin(translations[i].locale_id)! // TODO validate in controller
		mut params := arrays.concat(p, locale_id_bin)
		if title := translations[i].title {
			params = arrays.concat(params, title)
		} else {
			params = arrays.concat(params, firebird.Null{})
		}

		if subtitle := translations[i].subtitle {
			params = arrays.concat(params, subtitle)
		} else {
			params = arrays.concat(params, firebird.Null{})
		}

		if description := translations[i].description {
			params = arrays.concat(params, description)
		} else {
			params = arrays.concat(params, firebird.Null{})
		}

		stmt.execute(...params) or {
			stmt.close()!
			return err
		}
	}

	stmt.close()!
}

fn (mut app App) do_create_product(mut tx firebird.Transaction, p ProductRequest, product_id string, product_id_bin []u8) ! {
	mut c := ['id', 'handle']
	mut params := [firebird.Value(product_id_bin)]

	if handle := p.handle {
		params = arrays.concat(params, handle)
	} else {
		params = arrays.concat(params, product_id)
	}

	if is_giftcard := p.is_giftcard {
		c = arrays.concat(c, 'is_giftcard')
		params = arrays.concat(params, is_giftcard)
	}

	if status := p.status {
		c = arrays.concat(c, 'status')
		params = arrays.concat(params, status)
	}

	if thumbnail := p.thumbnail {
		c = arrays.concat(c, 'thumbnail')
		params = arrays.concat(params, thumbnail)
	}

	if collection_id := p.collection_id {
		c = arrays.concat(c, 'collection_id')
		collection_id_bin := luuid.to_bytes(collection_id)!
		params = arrays.concat(params, collection_id_bin)
	}

	if type_id := p.type_id {
		c = arrays.concat(c, 'type_id')
		type_id_bin := luuid.to_bytes(type_id)!
		params = arrays.concat(params, type_id_bin)
	}

	if discountable := p.discountable {
		c = arrays.concat(c, 'discountable')
		params = arrays.concat(params, discountable)
	}

	if metadata := p.metadata {
		c = arrays.concat(c, 'metadata')
		params = arrays.concat(params, metadata)
	}

	tx.execute('INSERT INTO product ( ${get_columns(c)} ) VALUES ( ${get_placeholders(c)} )',
		...params)!

	if translations := p.translations {
		app.do_create_product_translations(mut tx, product_id_bin, translations)!
	}

	if images := p.images {
		_, ids_bin := model_image_create(mut app, mut tx, images)!
		app.do_create_product_images(mut tx, product_id_bin, ids_bin)!
	}

	// TODO tag_ids

	if sales_channel_ids := p.sales_channel_ids {
		mut stmt := tx.prepare('INSERT INTO product_sales_channel (product_id, sales_channel_id) VALUES (?, ?)')!
		for i := 0; i < sales_channel_ids.len; i++ {
			sales_channel_id_bin := id_string_to_bin(sales_channel_ids[i]) or {
				stmt.close()!
				return err
			}
			stmt.execute(product_id_bin, sales_channel_id_bin) or {
				stmt.close()!
				return err
			}
		}
	} else {
		tx.execute('INSERT INTO product_sales_channel (product_id, sales_channel_id) 
		VALUES (?, (SELECT default_sales_channel_id FROM store))',
			product_id_bin)!
	}

	// TODO merge statement?
	if category_ids := p.category_ids {
		mut stmt := tx.prepare('INSERT INTO product_category_product (
					product_category_id, product_id) VALUES (?, ?)')!
		for i := 0; i < category_ids.len; i++ {
			category_id_bin := id_string_to_bin(category_ids[i]) or {
				stmt.close()!
				return err
			}
			stmt.execute(product_id_bin, category_id_bin) or {
				stmt.close()!
				return err
			}
		}
	}
}

fn (mut app App) create_product(p ProductRequest) !string {
	product_id, product_id_bin := app.new_id()
	mut tx := app.start_transaction()!

	app.do_create_product(mut tx, p, product_id, product_id_bin) or {
		tx.rollback()!
		return err
	}
	tx.commit()!
	return product_id
}

fn model_product_update(mut tx firebird.Transaction, id_bin []u8, ph ProductRequestHygienised) ! {
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

	if _ := ph.collection_id {
		c = arrays.concat(c, 'collection_id')
		params = arrays.concat(params, ph.collection_id_bin)
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

	if c.len != 0 {
		query := 'UPDATE product SET ${get_set_columns(c)} WHERE id = ?'
		params = arrays.concat(params, firebird.Value(id_bin))
		tx.execute(query, ...params)!
	}
}

fn (mut app App) delete_product(id string) ! {
	id_bin := id_string_to_bin(id)!
	mut tx := app.start_transaction()!
	tx.execute('UPDATE product SET deleted_at = CURRENT_TIMESTAMP WHERE id = ?', id_bin)!
	tx.commit()!
}
