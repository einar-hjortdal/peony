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
	deleted_at        firebird.DateTime
	handle            string
	is_giftcard       bool
	status            string
	thumbnail         string
	collection_id     string
	collection_id_bin []u8
	type_id           string
	type_id_bin       []u8
	discountable      bool
	metadata          firebird.NullString
mut:
	images         []Image
	options        []ProductOption
	variants       []Variant
	translations   []ProductTranslation
	sales_channels []SalesChannel
	// tags         []Tag
}

fn parse_product(v []firebird.Value) !Product {
	id_bin, _ := v[0].get_array_u8()!
	created_at, _ := v[1].get_date_time()!
	updated_at, _ := v[2].get_date_time()!
	deleted_at, _ := v[3].get_date_time()!
	handle, _ := v[4].get_string()!
	is_giftcard, _ := v[5].get_bool()!
	status, _ := v[6].get_string()!
	thumbnail, _ := v[7].get_string()!
	collection_id_bin, collection_id_bin_is_null := v[8].get_array_u8()!
	type_id_bin, type_id_bin_is_null := v[9].get_array_u8()!
	discountable, _ := v[10].get_bool()!

	id := id_bin_to_string(id_bin)!

	mut collection_id := ''
	mut type_id := ''

	if !collection_id_bin_is_null {
		collection_id = id_bin_to_string(collection_id_bin)!
	}

	if !type_id_bin_is_null {
		type_id = id_bin_to_string(type_id_bin)!
	}

	return Product{
		id:                id
		id_bin:            id_bin
		created_at:        created_at
		updated_at:        updated_at
		deleted_at:        deleted_at
		handle:            handle
		is_giftcard:       is_giftcard
		status:            status
		thumbnail:         thumbnail
		collection_id:     collection_id
		collection_id_bin: collection_id_bin
		type_id:           type_id
		type_id_bin:       type_id_bin
		discountable:      discountable
		metadata:          v[11].get_null_string()!
	}
}

// gather filtered and sorted id
fn do_retrieve_products__ids(mut tx firebird.Transaction, ph RetrieveProductParamsHygienised) !([][]u8, i64) {
	query := 'SELECT p.id, COUNT(*) OVER() FROM product p'
	mut params := []firebird.Value{}

	mut joins := ''
	// TODO change these joins into EXISTS
	joins = appendln(joins, 'LEFT JOIN product_tag_product pt ON pt.product_id = p.id')
	joins = appendln(joins, 'LEFT JOIN product_category_product pcp ON pcp.product_id = p.id')
	joins = appendln(joins, 'LEFT JOIN product_sales_channel psc ON psc.product_id = p.id')

	mut conditions := ''
	if !ph.with_deleted.is_set || (ph.with_deleted.is_set && !ph.with_deleted.v) {
		conditions = appendln(conditions, 'WHERE p.deleted_at IS NULL')
	}

	if ph.ids.is_set {
		conditions = appendln(conditions, 'AND p.id IN (${get_n_placeholders(i32(ph.ids_bin.len))})')
		params = arrays.concat(params, ...workaround_24757(ph.ids_bin))
	}

	if ph.handle.is_set {
		conditions = appendln(conditions, 'AND p.handle = ?')
		params = arrays.concat(params, ph.handle.v)
	}

	if ph.is_giftcard.is_set {
		conditions = appendln(conditions, 'AND p.is_giftcard = ?')
		params = arrays.concat(params, ph.is_giftcard.v)
	}

	if ph.status.is_set {
		conditions = appendln(conditions, 'AND p.status = ?')
		params = arrays.concat(params, ph.status.v)
	}

	if ph.collection_ids.is_set {
		conditions = appendln(conditions, 'AND p.collection_id IN ${get_n_placeholders(i32(ph.collection_ids_bin.len))}')
		params = arrays.concat(params, ...ph.collection_ids_bin)
	}

	if ph.type_ids.is_set {
		conditions = appendln(conditions, 'AND p.type_id IN ${get_n_placeholders(i32(ph.type_ids_bin.len))}')
		params = arrays.concat(params, ...ph.type_ids_bin)
	}

	if ph.tag_ids.is_set {
		conditions = appendln(conditions, 'AND pt.tag_id IN ${get_n_placeholders(i32(ph.tag_ids_bin.len))}')
		params = arrays.concat(params, ...ph.tag_ids_bin)
	}

	if ph.title.is_set {
		conditions = appendln(conditions, "AND EXISTS (
			SELECT 1
			FROM product_translations ptr
			WHERE ptr.product_id = p.id
				AND UPPER(ptr.title) LIKE UPPER('%' || ? || '%')
			)")
		params = arrays.concat(params, ph.title.v)
	}

	if ph.description.is_set {
		conditions = appendln(conditions, "AND EXISTS (
			SELECT 1
			FROM product_translations ptr
			WHERE ptr.product_id = p.id
				AND UPPER(ptr.description) LIKE UPPER('%' || ? || '%')
			)")
		params = arrays.concat(params, ph.description.v)
	}

	if ph.category_ids.is_set {
		conditions = appendln(conditions, 'AND pcp.product_category_id IN ${get_n_placeholders(i32(ph.category_ids_bin.len))}')
		params = arrays.concat(params, ...ph.category_ids_bin)
	}

	if ph.price_list_ids.is_set {
		conditions = appendln(conditions, 'AND ma.price_list_id IN ${get_n_placeholders(i32(ph.price_list_ids_bin.len))}')
		params = arrays.concat(params, ...ph.price_list_ids_bin)
	}

	if ph.sales_channel_ids.is_set {
		conditions = appendln(conditions, 'AND psc.sales_channel_id IN ${get_n_placeholders(i32(ph.sales_channel_ids_bin.len))}')
		params = arrays.concat(params, ...ph.sales_channel_ids_bin)
	}

	mut sorting := ''
	sorting = appendln(sorting, 'ORDER BY p.created_at ${get_sorting_order(ph.order)}')

	if ph.offset.is_set {
		sorting = appendln(sorting, 'OFFSET ? ROWS')
		params = arrays.concat(params, ph.offset.v)
	}

	sorting = appendln(sorting, 'FETCH NEXT ? ROWS ONLY')
	params = arrays.concat(params, get_fetch_amount(ph.fetch))

	data := tx.execute('${query}${joins}${conditions}${sorting}', ...params)!
	rows := data.rows()

	mut ids := [][]u8{len: rows.len}
	for i := 0; i < rows.len; i++ {
		id, _ := rows[i].values()[0].get_array_u8()!
		ids[i] = id
	}

	mut count := i64(0)
	if ids.len > 0 {
		c, _ := rows[0].values()[1].get_i64()!
		count = c
	}

	return ids, count
}

// retrieve all products using list of id, returns unsorted list
fn do_retrieve_products__products(mut tx firebird.Transaction, ids_bin [][]u8) ![]Product {
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
		WHERE id IN (${get_n_placeholders(i32(ids_bin.len))})',
		...workaround_24757(ids_bin))!

	rows := data.rows()

	mut products := []Product{}
	for i := 0; i < rows.len; i++ {
		product := parse_product(rows[i].values())!
		products = arrays.concat(products, product)
	}

	return products
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

// TODO use do_retrieve_product_variants instead
fn do_retrieve_products__variants(mut tx firebird.Transaction, ids_bin [][]u8) ![]Variant {
	data := tx.execute('SELECT
		id,
		created_at,
		updated_at,
		deleted_at,
		product_id,
		title,
		sku,
		barcode,
		ean,
		upc,
		variant_rank,
		allow_backorder,
		manage_inventory,
		hs_code,
		origin_country,
		mid_code,
		material,
		weight,
		length,
		height,
		width,
		metadata
		FROM product_variant
		WHERE product_id IN (${get_n_placeholders(i32(ids_bin.len))}) AND deleted_at IS NULL',
		...workaround_24757(ids_bin))!

	rows := data.rows()

	if rows.len == 0 {
		return []Variant{}
	}

	mut variants := []Variant{len: rows.len}
	for i := 0; i < rows.len; i++ {
		variants[i] = parse_variant(rows[i].values())!
	}

	return variants
}

fn retrieve_products(mut tx firebird.Transaction, ph RetrieveProductParamsHygienised) !([]Product, i64) {
	ids_bin, count := do_retrieve_products__ids(mut tx, ph)!
	len := i32(ids_bin.len)
	if len == 0 {
		return []Product{}, len
	}

	unsorted_products := do_retrieve_products__products(mut tx, ids_bin)!

	// Build a map for quick product lookups
	mut product_map := map[string]Product{}
	for i := 0; i < unsorted_products.len; i++ {
		prodct_id := unsorted_products[i].id
		product_map[prodct_id] = unsorted_products[i]
	}

	// There usually is a small number of sales_channel and a large number of product.
	// Using a single query results in a needlessly large payload with duplicated data.
	product_sales_channels := do_retrieve_product_sales_channels(mut tx, ids_bin)!
	sales_channels := do_retrieve_sales_channels(mut tx)!

	mut sales_channels_map := map[string]SalesChannel{}
	for i := 0; i < sales_channels.len; i++ {
		sales_channels_map[sales_channels[i].id] = sales_channels[i]
	}

	for i := 0; i < product_sales_channels.len; i++ {
		product_id := product_sales_channels[i].product_id
		sales_channel_id := product_sales_channels[i].sales_channel_id
		product_map[product_id].sales_channels = arrays.concat(product_map[product_id].sales_channels,
			sales_channels_map[sales_channel_id])
	}

	product_images := do_retrieve_product_images(mut tx, ids_bin)!
	if product_images.len != 0 {
		mut images_ids_bin := [][]u8{len: product_images.len}
		for i := 0; i < product_images.len; i++ {
			images_ids_bin[i] = product_images[i].id_bin
		}

		// TODO this is unnecessary, just transform ProductImage to Image and assign it to its owner
		images := do_retrieve_images(mut tx, images_ids_bin)!
		// Build a map for quick image lookups
		mut image_map := map[string]Image{}
		for i := 0; i < images.len; i++ {
			image_id := images[i].id
			image_map[image_id] = images[i]
		}

		for i := 0; i < product_images.len; i++ {
			image_id := product_images[i].id
			product_id_bin := product_images[i].product_id_bin
			product_id := id_bin_to_string(product_id_bin)!
			product_map[product_id].images = arrays.concat(product_map[product_id].images,
				image_map[image_id])
		}
	}

	translations := do_retrieve_product_translations(mut tx, ids_bin)!
	for i := 0; i < translations.len; i++ {
		product_id := translations[i].product_id
		product_map[product_id].translations = arrays.concat(product_map[product_id].translations,
			translations[i])
	}

	// replace variants with variant model call
	mut variants := do_retrieve_products__variants(mut tx, ids_bin)!
	mut options := model_product_options_retrieve_by_product_ids(mut tx, ids_bin)!
	if options.len != 0 {
		option_values := do_retrieve_products__option_values(mut tx, options)!

		// assign option_values to options and to variants
		for i := 0; i < option_values.len; i++ {
			for k := 0; k < options.len; k++ {
				if option_values[i].option_id == options[k].id {
					options[k].values = arrays.concat(options[k].values, option_values[i])
				}
			}
			for k := 0; k < variants.len; k++ {
				if option_values[i].variant_id == variants[k].id {
					variants[k].option_values = arrays.concat(variants[k].option_values,
						option_values[i])
				}
			}
		}
	}

	// assign options to products
	for i := 0; i < options.len; i++ {
		product_id := options[i].product_id
		product_map[product_id].options = arrays.concat(product_map[product_id].options,
			options[i])
	}

	// TODO would benefit from a refactor: use a map[string]ProductVariant
	if variants.len > 0 {
		money_amounts := do_retrieve_product_variant_money_amount(mut tx, variants)!
		for i := 0; i < variants.len; i++ {
			for k := 0; k < money_amounts.len; k++ {
				if variants[i].id_bin == money_amounts[k].variant_id_bin.value {
					variants[i].money_amounts = arrays.concat(variants[i].money_amounts,
						money_amounts[k])
				}
			}
		}
	}

	// assign variants to products
	for i := 0; i < variants.len; i++ {
		product_id := variants[i].product_id
		product_map[product_id].variants = arrays.concat(product_map[product_id].variants,
			variants[i])
	}

	// sort products according to ids array
	mut products := []Product{len: ids_bin.len}
	for i := 0; i < len; i++ {
		id := id_bin_to_string(ids_bin[i])!
		products[i] = product_map[id]
	}

	return products, count
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
		_, ids_bin := app.do_create_images(mut tx, images)!
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

	if collection_id := ph.collection_id {
		c = arrays.concat(c, 'collection_id')
		params = arrays.concat(params, ph.collection_id_bin)
	}

	if type_id := ph.type_id {
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
