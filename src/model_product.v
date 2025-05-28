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
	// sales_channels []SalesChannel        @[omitempty]
	// options  []Option  @[omitempty]
	variants []Variant @[omitempty]
	// translations   []ProductTranslations @[omitempty]
	// tags           []Tag                 @[omitempty]
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
	tags             ZeroArrayString
	title            ZeroString
	description      ZeroString
	category_id      ZeroArrayString
	sales_channel_id ZeroArrayString
	region_id        ZeroString
	currency_code    ZeroString
	locale_code      ZeroString
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
		tags:             zero_array_string(m, 'tags')
		title:            zero_string(m, 'title')
		description:      zero_string(m, 'description')
		category_id:      zero_array_string(m, 'category_id')
		sales_channel_id: zero_array_string(m, 'sales_channel_id')
		offset:           zero_i32(m, 'offset')
		fetch:            zero_i32(m, 'fetch')
		order:            zero_string(m, 'order')
	}
}

fn (mut app App) do_retrieve_products(mut tx firebird.Transaction, p RetrieveProductParams) ![]Product {
	// step 1: gather filtered and sorted id
	query := 'SELECT p.id FROM product p'
	mut params := []firebird.Value{}

	mut joins := ''
	joins = appendln(joins, 'LEFT JOIN product_variant pv ON pv.product_id = p.id')
	joins = appendln(joins, 'LEFT JOIN product_tags pt ON pt.product_id = p.id')
	joins = appendln(joins, 'LEFT JOIN product_category_product pcp ON pcp.product_id = p.id')
	joins = appendln(joins, 'LEFT JOIN product_sales_channel psc ON psc.product_id = p.id')
	joins = appendln(joins, 'LEFT JOIN product_translations pt ON pt.product_id = p.id')

	mut conditions := ''
	conditions = appendln(conditions, 'WHERE p.deleted_at IS NULL')

	if p.id.is_set {
		conditions = appendln(conditions, 'AND p.id IN ${get_n_placeholders(i32(p.id.v.len))}')
		params = arrays.concat(params, ...p.id.v)
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
		conditions = appendln(conditions, 'AND p.collection_id = ?')
		params = arrays.concat(params, p.collection_id.v)
	}

	if p.type_id.is_set {
		conditions = appendln(conditions, 'AND p.type_id = ?')
		params = arrays.concat(params, p.type_id.v)
	}

	mut sorting := ''
	if p.offset.is_set {
		sorting = appendln(sorting, 'OFFSET ? ROWS')
		params = arrays.concat(params, p.offset.v)
	}

	sorting = appendln(sorting, 'FETCH NEXT ? ROWS ONLY')
	params = arrays.concat(params, get_fetch_amount(p.fetch))

	conditions = appendln(conditions, 'AND pt.locale_code = ?')
	params = arrays.concat(params, p.locale_code.v)

	data := tx.execute('${query}${joins}${conditions}${sorting}', ...params)!

	if data.rows.len == 0 {
		return []Product{}
	}

	mut ids := []string{}
	for i := 0; i < data.rows.len; i++ {
		id, _ := data.rows[i].values[0].get_string()!
		ids = arrays.concat(ids, id)
	}

	// step 2: retrieve all products using sorted and filtered list of id
	// step 3: retrieve variants using product ids, assign to product with matching id
	// step 4: reorder retrieved products according to step 1 result
}

fn (mut app App) retrieve_products(p RetrieveProductParams) ![]Product {
	mut tx := app.start_transaction()!
	products := app.do_retrieve_products(mut tx, p) or {
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
