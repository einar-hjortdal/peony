module main

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
	}
}

// gather filtered and sorted id
fn do_retrieve_products__ids(mut tx firebird.Transaction, p RetrieveProductParams) !([][]u8, i64) {
	query := 'SELECT p.id, COUNT(*) OVER() FROM product p'
	mut params := []firebird.Value{}

	// TODO change these joins into EXISTS
	mut joins := ''
	joins = appendln(joins, 'LEFT JOIN product_variant pv ON pv.product_id = p.id')
	joins = appendln(joins, 'LEFT JOIN product_variant_money_amount pvm ON pvm.variant_id = pv.id')
	joins = appendln(joins, 'LEFT JOIN money_amount ma ON ma.id = pvm.money_amount_id')
	joins = appendln(joins, 'LEFT JOIN product_tag_product pt ON pt.product_id = p.id')
	joins = appendln(joins, 'LEFT JOIN product_category_product pcp ON pcp.product_id = p.id')
	joins = appendln(joins, 'LEFT JOIN product_sales_channel psc ON psc.product_id = p.id')

	mut conditions := ''
	conditions = appendln(conditions, 'WHERE p.deleted_at IS NULL')

	if p.id.is_set {
		mut ids_bin := [][]u8{len: p.id.v.len}
		for i := 0; i < p.id.v.len; i++ {
			id_bin := id_string_to_bin(p.id.v[i])!
			ids_bin[i] = id_bin
		}
		conditions = appendln(conditions, 'AND p.id IN (${get_n_placeholders(i32(p.id.v.len))})')
		params = arrays.concat(params, ...workaround_24757(ids_bin))
	}

	if p.handle.is_set {
		conditions = appendln(conditions, 'AND p.handle = ?')
		params = arrays.concat(params, p.handle.v)
	}

	if p.is_giftcard.is_set {
		conditions = appendln(conditions, 'AND p.is_giftcard = ?')
		params = arrays.concat(params, p.is_giftcard.v)
	}

	if p.status.is_set {
		conditions = appendln(conditions, 'AND p.status = ?')
		params = arrays.concat(params, p.status.v)
	}

	if p.collection_id.is_set {
		len := p.collection_id.v.len
		mut ids_bin := [][]u8{}
		for i := 0; i < len; i++ {
			id_bin := id_string_to_bin(p.collection_id.v[i])!
			ids_bin = arrays.concat(ids_bin, id_bin)
		}
		conditions = appendln(conditions, 'AND p.collection_id IN ${get_n_placeholders(i32(len))}')
		params = arrays.concat(params, ...ids_bin)
	}

	if p.type_id.is_set {
		len := p.type_id.v.len
		mut ids_bin := [][]u8{}
		for i := 0; i < len; i++ {
			id_bin := id_string_to_bin(p.type_id.v[i])!
			ids_bin = arrays.concat(ids_bin, id_bin)
		}

		conditions = appendln(conditions, 'AND p.type_id IN ${get_n_placeholders(i32(len))}')
		params = arrays.concat(params, ...ids_bin)
	}

	if p.tag_id.is_set {
		len := p.tag_id.v.len
		mut ids_bin := [][]u8{}
		for i := 0; i < len; i++ {
			id_bin := id_string_to_bin(p.tag_id.v[i])!
			ids_bin = arrays.concat(ids_bin, id_bin)
		}
		conditions = appendln(conditions, 'AND pt.tag_id IN ${get_n_placeholders(i32(len))}')
		params = arrays.concat(params, ...ids_bin)
	}

	if p.title.is_set {
		conditions = appendln(conditions, "AND EXISTS (
			SELECT 1
			FROM product_translations ptr
			WHERE ptr.product_id = p.id
				AND UPPER(ptr.title) LIKE UPPER('%' || ? || '%')
			)")
		params = arrays.concat(params, p.title.v)
	}

	if p.description.is_set {
		conditions = appendln(conditions, "AND EXISTS (
			SELECT 1
			FROM product_translations ptr
			WHERE ptr.product_id = p.id
				AND UPPER(ptr.description) LIKE UPPER('%' || ? || '%')
			)")
		params = arrays.concat(params, p.description.v)
	}

	if p.category_id.is_set {
		len := p.category_id.v.len
		mut ids_bin := [][]u8{}
		for i := 0; i < len; i++ {
			id_bin := id_string_to_bin(p.category_id.v[i])!
			ids_bin = arrays.concat(ids_bin, id_bin)
		}
		conditions = appendln(conditions, 'AND pcp.product_category_id IN ${get_n_placeholders(i32(len))}')
		params = arrays.concat(params, ...ids_bin)
	}

	if p.price_list_id.is_set {
		len := p.price_list_id.v.len
		mut ids_bin := [][]u8{}
		for i := 0; i < len; i++ {
			id_bin := id_string_to_bin(p.price_list_id.v[i])!
			ids_bin = arrays.concat(ids_bin, id_bin)
		}
		conditions = appendln(conditions, 'AND ma.price_list_id IN ${get_n_placeholders(i32(len))}')
		params = arrays.concat(params, ...ids_bin)
	}

	if p.sales_channel_id.is_set {
		len := p.sales_channel_id.v.len
		mut ids_bin := [][]u8{}
		for i := 0; i < len; i++ {
			id_bin := id_string_to_bin(p.sales_channel_id.v[i])!
			ids_bin = arrays.concat(ids_bin, id_bin)
		}
		conditions = appendln(conditions, 'AND psc.sales_channel_id IN ${get_n_placeholders(i32(len))}')
		params = arrays.concat(params, ...ids_bin)
	}

	mut sorting := ''
	sorting = appendln(sorting, 'ORDER BY p.created_at ${get_sorting_order(p.order)}')

	if p.offset.is_set {
		sorting = appendln(sorting, 'OFFSET ? ROWS')
		params = arrays.concat(params, p.offset.v)
	}

	sorting = appendln(sorting, 'FETCH NEXT ? ROWS ONLY')
	params = arrays.concat(params, get_fetch_amount(p.fetch))

	data := tx.execute('${query}${joins}${conditions}${sorting}', ...params)!

	mut ids := [][]u8{len: data.rows.len}
	for i := 0; i < data.rows.len; i++ {
		id, _ := data.rows[i].values[0].get_array_u8()!
		ids[i] = id
	}

	mut count := i64(0)
	if ids.len > 0 {
		c, _ := data.rows[0].values[1].get_i64()!
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
		discountable
		FROM product
		WHERE id IN (${get_n_placeholders(i32(ids_bin.len))})',
		...workaround_24757(ids_bin))!

	mut products := []Product{}
	for i := 0; i < data.rows.len; i++ {
		product := parse_product(data.rows[i].values)!
		products = arrays.concat(products, product)
	}

	return products
}

fn do_retrieve_products__option_values(mut tx firebird.Transaction, po []ProductOption) ![]ProductOptionValue {
	mut option_ids_bin := [][]u8{}
	for i := 0; i < po.len; i++ {
		option_ids_bin = arrays.concat(option_ids_bin, po[i].id_bin)
	}

	return do_retrieve_product_option_values(mut tx, option_ids_bin)!
}

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
		inventory_quantity,
		allow_backorder,
		manage_inventory,
		hs_code,
		origin_country,
		mid_code,
		weight,
		length,
		height,
		width
		FROM product_variant
		WHERE product_id IN (${get_n_placeholders(i32(ids_bin.len))})',
		...workaround_24757(ids_bin))!

	if data.rows.len == 0 {
		return []Variant{}
	}

	mut variants := []Variant{len: data.rows.len}
	for i := 0; i < data.rows.len; i++ {
		variants[i] = parse_variant(data.rows[i].values)!
	}

	return variants
}

fn do_retrieve_products(mut tx firebird.Transaction, p RetrieveProductParams) !([]Product, i64) {
	ids_bin, count := do_retrieve_products__ids(mut tx, p)!
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

	product_images := do_retrieve_product_images(mut tx, ids_bin)!
	if product_images.len != 0 {
		mut images_ids_bin := [][]u8{len: product_images.len}
		for i := 0; i < product_images.len; i++ {
			images_ids_bin[i] = product_images[i].id_bin
		}

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

	mut variants := do_retrieve_products__variants(mut tx, ids_bin)!
	mut options := do_retrieve_product_options(mut tx, ids_bin)!
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

fn (mut app App) retrieve_products(p RetrieveProductParams) !([]Product, i64) {
	mut tx := app.start_transaction()!
	products, count := do_retrieve_products(mut tx, p) or {
		tx.rollback()!
		return err
	}
	tx.rollback()!
	return products, count
}

fn (mut app App) retrieve_product_by_id(id string) !Product {
	m := {
		'id': id
	}
	p := extract_retrieve_products_params(m)

	products, count := app.retrieve_products(p)!
	if count == 0 {
		return error(format_error_message('No product found with the given id'))
	}

	return products[0]
}

fn build_query_create_product(product_id string, product_id_bin []u8, p ProductData) !(string, []firebird.Value) {
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

	q := 'INSERT INTO product ( ${get_columns(c)} ) VALUES ( ${get_placeholders(c)} )'
	return q, params
}

fn (mut app App) do_create_product_translations(mut tx firebird.Transaction, product_id_bin []u8, translations []ProductTranslationData) ! {
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

fn (mut app App) do_create_product(mut tx firebird.Transaction, p ProductData, product_id string, product_id_bin []u8) ! {
	product_query, product_params := build_query_create_product(product_id, product_id_bin,
		p)!
	tx.execute(product_query, ...product_params)!

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

fn (mut app App) create_product(p ProductData) !string {
	product_id, product_id_bin := app.new_id()!
	mut tx := app.start_transaction()!

	app.do_create_product(mut tx, p, product_id, product_id_bin) or {
		tx.rollback()!
		return err
	}
	tx.commit()!
	return product_id
}

fn (mut app App) do_update_product(mut tx firebird.Transaction, id string, p ProductData) ! {
	id_bin := id_string_to_bin(id)!
	mut c := []string{}
	mut params := []firebird.Value{}

	if handle := p.handle {
		c = arrays.concat(c, 'handle')
		params = arrays.concat(params, handle)
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

	if c.len != 0 {
		query := 'UPDATE product SET ${get_set_columns(c)} WHERE id = ?'
		params = arrays.concat(params, firebird.Value(id_bin))
		tx.execute(query, ...params)!
	}

	// TODO
	// tag_ids

	if image_urls := p.images {
		app.do_update_product_images(mut tx, id_bin, image_urls)!
	}

	if sales_channel_ids := p.sales_channel_ids {
		mut sales_channel_ids_bin := [][]u8{}
		for i := 0; i < sales_channel_ids.len; i++ {
			sales_channel_id_bin := id_string_to_bin(sales_channel_ids[i])!
			sales_channel_ids_bin = arrays.concat(sales_channel_ids_bin, sales_channel_id_bin)
		}

		app.do_update_product_sales_channels(mut tx, id_bin, sales_channel_ids_bin)!
	}

	if category_ids := p.category_ids {
		mut category_ids_bin := [][]u8{}
		for i := 0; i < category_ids.len; i++ {
			category_id_bin := id_string_to_bin(category_ids[i])!
			category_ids_bin = arrays.concat(category_ids_bin, category_id_bin)
		}
		app.do_update_product_categories(mut tx, id_bin, category_ids_bin)!
	}

	if translations := p.translations {
		app.do_update_product_translations(mut tx, id_bin, translations)!
	}

	if options := p.options {
		if options.len == 0 {
			app.do_delete_product_options(mut tx, id_bin)!
		} else {
			app.do_update_product_options(mut tx, id_bin, options)!
		}
	}
}

fn (mut app App) update_product(id string, p ProductData) ! {
	mut tx := app.start_transaction()!
	app.do_update_product(mut tx, id, p) or {
		tx.rollback()!
		return err
	}
	tx.commit()!
}

fn (mut app App) delete_product(id string) ! {
	id_bin := id_string_to_bin(id)!
	mut tx := app.start_transaction()!
	tx.execute('UPDATE product SET deleted_at = CURRENT_TIMESTAMP WHERE id = ?', id_bin)!
	tx.commit()!
}

fn (mut app App) do_create_product_option(mut tx firebird.Transaction, id_bin []u8, product_id_bin []u8, p ProductOptionData) ! {
	tx.execute('INSERT INTO product_option (id, product_id) VALUES(?, ?)', id_bin, product_id_bin)!
}

// fn (mut app App) update_product_option_translation(id string, p ProductOptionTranslationData) ! {
// 	id_bin := id_string_to_bin(id)!
// 	mut tx := app.start_transaction()!
// 	tx.execute('UPDATE product_option_translations (product_option_id, locale_id, title)
// 		Values(?, ?, ?)',
// 		id_bin, p.locale_id, p.title)!
// 	tx.commit()!
// }

// fn (mut app App) delete_product_option_translation(id string, locale_id string) ! {
// 	id_bin := id_string_to_bin(id)!
// 	mut tx := app.start_transaction()!
// 	tx.execute('UPDATE product_option_translations SET deleted_at = CURRENT_TIMESTAMP
// 		WHERE product_option_id = ? AND locale_id = ?',
// 		id_bin, locale_id)!
// 	tx.commit()!
// }
