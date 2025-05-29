module main

import arrays
import einar_hjortdal.firebird
import einar_hjortdal.luuid

const product_status_draft = 'draft'
const product_status_proposed = 'proposed'
const product_status_published = 'published'
const product_status_rejected = 'rejected'

struct Product {
	id            string
	created_at    firebird.DateTime
	updated_at    firebird.DateTime
	deleted_at    firebird.DateTime @[omitempty]
	handle        string
	is_giftcard   bool
	status        string
	thumbnail     string @[omitempty]
	collection_id string @[omitempty]
	type_id       string @[omitempty]
	discountable  bool
mut:
	images       []Image               @[omitempty]
	options      []ProductOption       @[omitempty]
	variants     []Variant             @[omitempty]
	translations []ProductTranslations @[omitempty]
	// tags         []Tag                 @[omitempty]
}

fn parse_product(v []firebird.Value) !Product {
	id_bin, _ := v[0].get_array_u8()!
	created_at, _ := v[1].get_date_time()!
	updated_at, _ := v[2].get_date_time()!
	deleted_at, _ := v[3].get_date_time()!
	handle, _ := v[4].get_string()!
	is_giftcard, _ := v[5].get_bool()!
	status, _ := v[6].get_string()!
	thumbnail, _ := v[8].get_string()!
	collection_id_bin, collection_id_bin_is_null := v[9].get_array_u8()!
	type_id_bin, type_id_bin_is_null := v[10].get_array_u8()!
	discountable, _ := v[11].get_bool()!

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
		id:            id
		created_at:    created_at
		updated_at:    updated_at
		deleted_at:    deleted_at
		handle:        handle
		is_giftcard:   is_giftcard
		status:        status
		thumbnail:     thumbnail
		collection_id: collection_id
		type_id:       type_id
		discountable:  discountable
	}
}

struct RetrieveProductParams {
	id               ZeroArrayString
	handle           ZeroString
	is_giftcard      ZeroBool
	status           ZeroString
	collection_id    ZeroArrayString
	type_id          ZeroArrayString
	tag_id           ZeroArrayString
	title            ZeroString
	description      ZeroString
	category_id      ZeroArrayString
	price_list_id    ZeroArrayString
	sales_channel_id ZeroArrayString
	region_id        ZeroString
	currency_code    ZeroString
	offset           ZeroI32
	fetch            ZeroI32
	order            ZeroString
}

fn extract_retrieve_products_params(m map[string]string) RetrieveProductParams {
	return RetrieveProductParams{
		id:               zero_array_string(m, 'id')
		handle:           zero_string(m, 'handle')
		is_giftcard:      zero_bool(m, 'is_giftcard')
		status:           zero_string(m, 'status')
		collection_id:    zero_array_string(m, 'collection_id')
		type_id:          zero_array_string(m, 'type_id')
		tag_id:           zero_array_string(m, 'tag_id')
		title:            zero_string(m, 'title')
		description:      zero_string(m, 'description')
		category_id:      zero_array_string(m, 'category_id')
		price_list_id:    zero_array_string(m, 'price_list_id')
		sales_channel_id: zero_array_string(m, 'sales_channel_id')
		region_id:        zero_string(m, 'region_id') // TODO used by /store/
		currency_code:    zero_string(m, 'currency_code') // TODO used by /store/
		offset:           zero_i32(m, 'offset')
		fetch:            zero_i32(m, 'fetch')
		order:            zero_string(m, 'order')
	}
}

// gather filtered and sorted id
fn do_retrieve_products__ids(mut tx firebird.Transaction, p RetrieveProductParams) ![][]u8 {
	query := 'SELECT p.id FROM product p'
	mut params := []firebird.Value{}

	mut joins := ''
	joins = appendln(joins, 'LEFT JOIN product_variant pv ON pv.product_id = p.id')
	joins = appendln(joins, 'LEFT JOIN product_variant_money_amount pvm ON pvm.variant_id = pv.id')
	joins = appendln(joins, 'LEFT JOIN money_amount ma ON ma.id = pvm.money_amount_id')
	joins = appendln(joins, 'LEFT JOIN product_tags pt ON pt.product_id = p.id')
	joins = appendln(joins, 'LEFT JOIN product_category_product pcp ON pcp.product_id = p.id')
	joins = appendln(joins, 'LEFT JOIN product_sales_channel psc ON psc.product_id = p.id')
	joins = appendln(joins, 'LEFT JOIN product_translations ptr ON ptr.product_id = p.id')

	mut conditions := ''
	conditions = appendln(conditions, 'WHERE p.deleted_at IS NULL')

	if p.id.is_set {
		len := p.id.v.len
		mut ids_bin := [][]u8{}
		for i := 0; i < len; i++ {
			id_bin := id_string_to_bin(p.id.v[i])!
			ids_bin = arrays.concat(ids_bin, id_bin)
		}
		conditions = appendln(conditions, 'AND p.id IN ${get_n_placeholders(i32(len))}')
		params = arrays.concat(params, ...ids_bin)
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

		conditions = appendln(conditions, 'AND IN ${get_n_placeholders(i32(len))}')
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
		conditions = appendln(conditions, "AND UPPER(ptr.title) LIKE UPPER('%' || ? || '%')")
		params = arrays.concat(params, p.title.v)
	}

	if p.description.is_set {
		conditions = appendln(conditions, "AND UPPER(ptr.description) LIKE UPPER('%' || ? || '%')")
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
	if p.offset.is_set {
		sorting = appendln(sorting, 'OFFSET ? ROWS')
		params = arrays.concat(params, p.offset.v)
	}

	sorting = appendln(sorting, 'FETCH NEXT ? ROWS ONLY')
	params = arrays.concat(params, get_fetch_amount(p.fetch))

	data := tx.execute('${query}${joins}${conditions}${sorting}', ...params)!

	mut ids := [][]u8{}
	for i := 0; i < data.rows.len; i++ {
		id, _ := data.rows[i].values[0].get_array_u8()!
		ids = arrays.concat(ids, id)
	}

	return ids
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
		WHERE id IN ${get_n_placeholders(i32(ids_bin.len))}',
		...ids_bin)!

	mut products := []Product{}
	for i := 0; i < data.rows.len; i++ {
		product := parse_product(data.rows[i].values)!
		products = arrays.concat(products, product)
	}

	return products
}

fn do_retrieve_products__translations(mut tx firebird.Transaction, ids_bin [][]u8) ![]ProductTranslations {
	data := tx.execute('SELECT 
		product_id,
		locale_code,
		created_at,
		updated_at,
		deleted_at,
		title,
		subtitle,
		description
		FROM product_translations
		WHERE product_id IN ${get_n_placeholders(i32(ids_bin.len))}',
		...ids_bin)!

	mut translations := []ProductTranslations{}
	for i := 0; i < data.rows.len; i++ {
		translation := parse_product_translation(data.rows[i].values)!
		translations = arrays.concat(translations, translation)
	}

	return translations
}

fn do_retrieve_products__options(mut tx firebird.Transaction, ids_bin [][]u8) ![]ProductOption {
	mut data := tx.execute('SELECT id, created_at, updated_at, deleted_at, product_id
			FROM product_option
			WHERE id IN ${get_n_placeholders(i32(ids_bin.len))}',
		...ids_bin)!

	mut options := []ProductOption{}
	mut option_ids_bin := [][]u8{}
	for i := 0; i < data.rows.len; i++ {
		option := parse_product_option(data.rows[i].values)!
		option_id_bin := id_string_to_bin(option.id)!
		options = arrays.concat(options, option)
		option_ids_bin = arrays.concat(option_ids_bin, option_id_bin)
	}

	translations := do_retrieve_product_option_translations(mut tx, option_ids_bin)!

	for i := 0; i < translations.len; i++ {
		for k := 0; k < options.len; k++ {
			if translations[i].product_option_id == options[k].id {
				options[k].translations = arrays.concat(options[k].translations, translations[i])
			}
		}
	}

	return options
}

fn do_retrieve_products__option_values(mut tx firebird.Transaction, po []ProductOption) ![]ProductOptionValue {
	mut option_ids_bin := [][]u8{}
	for i := 0; i < po.len; i++ {
		option_id_bin := id_string_to_bin(po[i].id)!
		option_ids_bin = arrays.concat(option_ids_bin, option_id_bin)
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
		width,
		title
		FROM product_variant
		WHERE product_id IN ${get_n_placeholders(i32(ids_bin.len))}',
		...ids_bin)!

	mut variants := []Variant{}
	for i := 0; i < data.rows.len; i++ {
		variant := parse_variant(data.rows[i].values)!
		variants = arrays.concat(variants, variant)
	}

	variants = do_retrieve_product_variant_money_amount(mut tx, variants)!

	return variants
}

// TODO: create maps for fast lookups of data
// TODO: when parsing structs, it would be better to return ids in binary format instead of converting back and forth
fn do_retrieve_products(mut tx firebird.Transaction, p RetrieveProductParams) ![]Product {
	ids_bin := do_retrieve_products__ids(mut tx, p)!
	if ids_bin.len == 0 {
		return []Product{}
	}

	unsorted_products := do_retrieve_products__products(mut tx, ids_bin)!

	// sort products according to ids array
	mut products := []Product{}
	for i := 0; i < ids_bin.len; i++ {
		id := id_bin_to_string(ids_bin[i])!
		for k := 0; k < unsorted_products.len; k++ {
			if id == unsorted_products[k].id {
				products = arrays.concat(products, unsorted_products[k])
				break
			}
		}
	}

	product_images := do_retrieve_product_images(mut tx, ids_bin)!
	mut images_ids_bin := [][]u8{}
	for i := 0; i < product_images.len; i++ {
		images_id_bin := id_string_to_bin(product_images[i].image_id)!
		images_ids_bin = arrays.concat(images_ids_bin, images_id_bin)
	}

	images := do_retrieve_images(mut tx, images_ids_bin)!
	for i := 0; i < product_images.len; i++ {
		for k := 0; k < products.len; k++ {
			if products[k].id == product_images[i].product_id {
				for j := 0; j < images.len; j++ {
					if images[j].id == product_images[i].image_id {
						products[k].images = arrays.concat(products[k].images, images[j])
						break // Stop searching for images once found
					}
				}
				break // Stop searching for products once found
			}
		}
	}

	translations := do_retrieve_products__translations(mut tx, ids_bin)!
	for i := 0; i < translations.len; i++ {
		for k := 0; k < products.len; k++ {
			if translations[i].product_id == products[k].id {
				products[k].translations = arrays.concat(products[k].translations, translations[i])
			}
		}
	}

	mut variants := do_retrieve_products__variants(mut tx, ids_bin)!
	mut options := do_retrieve_products__options(mut tx, ids_bin)!
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
				variants[k].option_values = arrays.concat(variants[k].option_values, option_values[i])
			}
		}
	}

	// assign variants to products
	for i := 0; i < variants.len; i++ {
		for k := 0; k < products.len; k++ {
			if variants[i].product_id == products[k].id {
				products[k].variants = arrays.concat(products[k].variants, variants[i])
				break
			}
		}
	}

	return products
}

fn (mut app App) retrieve_products(p RetrieveProductParams) ![]Product {
	mut tx := app.start_transaction()!
	products := do_retrieve_products(mut tx, p) or {
		tx.rollback()!
		return err
	}
	tx.rollback()!
	return products
}

fn (mut app App) retrieve_product_by_id(id string) !Product {
	m := {
		id: id
	}
	p := extract_retrieve_products_params(m)

	products := app.retrieve_products(p)!
	if products.len == 0 {
		return error(format_error_message('No product found with the given id'))
	}

	return products[0]
}

// TODO use option types
struct NewProductData {
	title          string
	subtitle       string
	description    string
	is_giftcard    bool
	discountable   bool
	images         []string
	thumbnail      string
	handle         string
	status         string
	type_id        string
	collection_id  string
	tags           []string
	sales_channels []string
	categories     []string
	options        []string
}

fn build_query_create_product(product_id string, product_id_bin []u8, p NewProductData) !(string, []firebird.Value) {
	mut c := ['id', 'handle']
	mut params := [firebird.Value(product_id_bin)]

	if p.handle == '' {
		params = arrays.concat(params, product_id)
	} else {
		params = arrays.concat(params, p.handle)
	}

	if p.is_giftcard {
		c = arrays.concat(c, 'is_giftcard')
		params = arrays.concat(params, p.is_giftcard)
	}

	if p.status != '' {
		c = arrays.concat(c, 'status')
		params = arrays.concat(params, p.status)
	}

	if p.thumbnail != '' {
		c = arrays.concat(c, 'thumbnail')
		params = arrays.concat(params, p.thumbnail)
	}

	if p.collection_id != '' {
		c = arrays.concat(c, 'collection_id')
		collection_id_bin := luuid.to_bytes(p.collection_id)!
		params = arrays.concat(params, collection_id_bin)
	}

	if p.type_id != '' {
		c = arrays.concat(c, 'type_id')
		type_id_bin := luuid.to_bytes(p.type_id)!
		params = arrays.concat(params, type_id_bin)
	}

	if p.discountable {
		c = arrays.concat(c, 'discountable')
		params = arrays.concat(params, p.discountable)
	}

	q := 'INSERT INTO product ( ${get_columns(c)} ) VALUES ( ${get_placeholders(c)} )'
	return q, params
}

fn build_query_create_product_variant(variant_id string, variant_id_bin []u8, product_id_bin []u8, p NewProductData) !(string, []firebird.Value) {
	mut c := ['id', 'product_id']
	mut params := [firebird.Value(variant_id_bin), product_id_bin]

	q := 'INSERT INTO product_variant ( ${get_columns(c)} ) VALUES ( ${get_placeholders(c)} )'
	return q, params
}

fn build_query_create_product_translations(product_id_bin []u8, p NewProductData) !(string, []firebird.Value) {
	mut c := ['product_id', 'title']
	mut params := [firebird.Value(product_id_bin), p.title]

	if p.subtitle != '' {
		c = arrays.concat(c, 'subtitle')
		params = arrays.concat(params, p.subtitle)
	}

	if p.description != '' {
		c = arrays.concat(c, 'description')
		params = arrays.concat(params, p.description)
	}

	q := 'INSERT INTO product_translations ( locale_code, ${get_columns(c)} ) 
		SELECT s.locale_code, ${get_placeholders(c)} 
		FROM store s FETCH NEXT 1 ROWS ONLY'
	return q, params
}

fn build_query_create_product_variant_translations() {}

fn (mut app App) create_product(p NewProductData) !string {
	product_id, product_id_bin := app.new_id()!
	product_query, product_params := build_query_create_product(product_id, product_id_bin,
		p)!

	variant_id, variant_id_bin := app.new_id()!
	product_variant_query, product_variant_params := build_query_create_product_variant(variant_id,
		variant_id_bin, product_id_bin, p)!
	product_translations_query, product_translations_params := build_query_create_product_translations(product_id_bin,
		p)!

	mut tx := app.start_transaction()!

	tx.execute(product_query, ...product_params) or {
		tx.rollback()!
		return err
	}

	tx.execute(product_variant_query, ...product_variant_params) or {
		tx.rollback()!
		return err
	}

	tx.execute(product_translations_query, ...product_translations_params) or {
		tx.rollback()!
		return err
	}

	tx.commit()!
	return product_id
}

fn (mut app App) delete_product(id string) ! {
	id_bin := id_string_to_bin(id)!
	mut tx := app.start_transaction()!
	tx.execute('UPDATE product SET deleted_at = CURRENT_TIMESTAMP WHERE id = ?', id_bin)!
	tx.commit()!
}

fn (mut app App) create_product_option(product_id string, title string) !string {
	id, id_bin := app.new_id()!
	product_id_bin := id_string_to_bin(product_id)!
	mut tx := app.start_transaction()!
	tx.execute('INSERT INTO product_option (id, product_id) VALUES(?, ?)', id_bin, product_id_bin)!
	tx.execute('INSERT INTO product_option_translations (product_option_id, locale_code, title) 
		SELECT ?, default_locale_code, ? FROM store FETCH NEXT 1 ROWS ONLY',
		id_bin, title)!
	tx.commit()!
	return id
}

fn (mut app App) delete_product_option(id string) ! {
	id_bin := id_string_to_bin(id)!
	mut tx := app.start_transaction()!
	tx.execute('UPDATE product_option SET deleted_at = CURRENT_TIMESTAMP WHERE id = ?',
		id_bin)!
	tx.commit()!
}

struct UpdateProductOptionData {
	title string
}

fn (mut app App) update_product_option(id string, p UpdateProductOptionData) !string {
	id_bin := id_string_to_bin(id)!
	mut tx := app.start_transaction()!
	tx.execute('UPDATE product_option_translations (product_option_id, locale_code, title) 
			SELECT ?, default_locale_code, ? FROM store FETCH NEXT 1 ROWS ONLY',
		id_bin, p.title)!
	tx.commit()!
	return id
}

struct ProductOptionTranslationData {
	title       string
	locale_code string
}

fn (mut app App) update_product_option_translation(id string, p ProductOptionTranslationData) ! {
	id_bin := id_string_to_bin(id)!
	mut tx := app.start_transaction()!
	tx.execute('UPDATE product_option_translations (product_option_id, locale_code, title) 
		Values(?, ?, ?)',
		id_bin, p.locale_code, p.title)!
	tx.commit()!
}

fn (mut app App) delete_product_option_translation(id string, locale_code string) ! {
	id_bin := id_string_to_bin(id)!
	mut tx := app.start_transaction()!
	tx.execute('UPDATE product_option_translations SET deleted_at = CURRENT_TIMESTAMP 
		WHERE product_option_id = ? AND locale_code = ?',
		id_bin, locale_code)!
	tx.commit()!
}
