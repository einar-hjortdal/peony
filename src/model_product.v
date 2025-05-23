module main

import arrays
import einar_hjortdal.firebird
import einar_hjortdal.luuid

const product_status_draft = 'draft'
const product_status_proposed = 'proposed'
const product_status_published = 'published'
const product_status_rejected = 'rejected'

// A product is a saleable item that holds general information. It must include at least one product_variant,
// where each product variant defines different options to purchase the product with (for example, different
// sizes or colors). The prices and inventory of the product are defined on the variant level. Public
// descriptive data such as name and description are defined as product_translations.
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
	// from product_variant
	origin_country string @[omitempty]
	weight         i32    @[omitempty]
	length         i32    @[omitempty]
	height         i32    @[omitempty]
	width          i32    @[omitempty]
	// from product_translations
	title       string @[omitempty]
	subtitle    string @[omitempty]
	description string @[omitempty]
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
	collection_id_bin, _ := v[9].get_array_u8()!
	type_id_bin, _ := v[10].get_array_u8()!
	discountable, _ := v[11].get_bool()!
	origin_country, _ := v[12].get_string()!
	weight, _ := v[13].get_i32()!
	length, _ := v[14].get_i32()!
	height, _ := v[15].get_i32()!
	width, _ := v[16].get_i32()!
	title, _ := v[17].get_string()!
	subtitle, _ := v[18].get_string()!
	description, _ := v[19].get_string()!

	id := id_from_bin(id_bin)!
	collection_id := id_from_bin(collection_id_bin)!
	type_id := id_from_bin(type_id_bin)!

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
		// from product_variant
		origin_country: origin_country
		weight:         weight
		length:         length
		height:         height
		width:          width
		// from product_translations
		title:       title
		subtitle:    subtitle
		description: description
	}
}

struct ProductParams {
	id               []string
	handle           string
	is_giftcard      bool
	status           string
	collection_id    []string
	type_id          []string
	tags             []string
	title            string
	description      string
	category_id      []string
	sales_channel_id []string
	region_id        string
	currency_code    string
	locale_code      string
	offset           i32
	fetch            i32
	order            string
}

fn build_query_retrieve_products(p ProductParams) (string, []firebird.Value) {
	fetch := i32_or_max(p.fetch)

	base_query := 'SELECT
		p.id,
		p.created_at,
		p.updated_at,
		p.deleted_at,
		p.handle,
		p.is_giftcard,
		p.status,
		p.thumbnail,
		p.collection_id,
		p.type_id,
		p.discountable,

		pv.origin_country,
		pv.weight,
		pv.length,
		pv.height,
		pv.width,

		pt.title,
		pt.subtitle,
		pt.description,

		FROM product p'

	mut joins := '
		LEFT JOIN product_variant pv
		ON pv.product_id = p.id

		LEFT JOIN product_translations pt
		ON pt.product_id = p.id'

	mut conditions := '
		WHERE p.deleted_at IS NULL
		AND pv.variant_rank IS 0'

	sorting := '
		OFFSET ? ROWS
		FETCH NEXT ? ROWS ONLY
		ORDER BY p.created_at ${parse_order(p.order)}'

	mut params := []firebird.Value{}

	if p.locale_code == '' {
		joins += '
			LEFT JOIN store s ON TRUE
			AND pt.locale_code = s.default_locale_code'
	} else {
		conditions += '
		AND pt.locale_code = ?'
		params = arrays.concat(params, p.locale_code)
	}

	params = arrays.concat(params, p.offset, fetch)

	return '${base_query}${joins}${conditions}${sorting}', params
}

fn (mut app App) retrieve_products(p ProductParams) ![]Product {
	query, params := build_query_retrieve_products(p)
	mut tx := app.start_transaction()!
	data := tx.execute(query, ...params)!
	tx.rollback()!

	mut products := []Product{}
	for i := 0; i < data.rows.len; i++ {
		product := parse_product(data.rows[i].values)!
		products = arrays.concat(products, product)
	}
	return products
}

fn build_query_retrieve_product(id string, locale_code string) !(string, []firebird.Value) {
	id_bin := id_to_bin(id)!

	base_query := 'SELECT
		p.id,
		p.created_at,
		p.updated_at,
		p.deleted_at,
		p.handle,
		p.is_giftcard,
		p.status,
		p.thumbnail,
		p.collection_id,
		p.type_id,
		p.discountable,

		pv.origin_country,
		pv.weight,
		pv.length,
		pv.height,
		pv.width,

		pt.title,
		pt.subtitle,
		pt.description,

		FROM product p'

	mut joins := '
		LEFT JOIN product_variant pv
		ON pv.product_id = p.id

		LEFT JOIN product_translations pt
		ON pt.product_id = p.id'

	mut conditions := '
		WHERE id = ?
		AND pv.variant_rank IS 0'

	mut params := [firebird.Value(id_bin)]

	if locale_code == '' {
		joins += '
			LEFT JOIN store s ON TRUE
			AND pt.locale_code = s.default_locale_code'
	} else {
		conditions += '
		AND pt.locale_code = ?'
		params = arrays.concat(params, locale_code)
	}

	return '${base_query}${joins}${conditions}', params
}

fn (mut app App) retrieve_product_by_id(id string, locale_code string) !Product {
	mut tx := app.start_transaction()!
	query, params := build_query_retrieve_product(id, locale_code)!
	data := tx.execute(query, ...params)!
	if data.rows.len == 0 {
		return error(format_error_message('No product found'))
	}
	return parse_product(data.rows[0].values)
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
	id_bin := id_to_bin(id)!
	mut tx := app.start_transaction()!
	tx.execute('UPDATE product SET deleted_at = CURRENT_TIMESTAMP WHERE id = ?', id_bin)!
	tx.commit()!
}

fn (mut app App) create_product_option(product_id string, title string) !string {
	id, id_bin := app.new_id()!
	product_id_bin := id_to_bin(product_id)!
	mut tx := app.start_transaction()!
	tx.execute('INSERT INTO product_option (id, product_id) VALUES(?, ?)', id_bin, product_id_bin)!
	tx.execute('INSERT INTO product_option_translations (product_option_id, locale_code, title) 
		SELECT ?, default_locale_code, ? FROM store FETCH NEXT 1 ROWS ONLY',
		id_bin, title)!
	tx.commit()!
	return id
}

fn (mut app App) delete_product_option(id string) ! {
	id_bin := id_to_bin(id)!
	mut tx := app.start_transaction()!
	tx.execute('UPDATE product_option SET deleted_at = CURRENT_TIMESTAMP WHERE id = ?',
		id_bin)!
	tx.commit()!
}

struct UpdateProductOptionData {
	title string
}

fn (mut app App) update_product_option(id string, p UpdateProductOptionData) !string {
	id_bin := id_to_bin(id)!
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
	id_bin := id_to_bin(id)!
	mut tx := app.start_transaction()!
	tx.execute('UPDATE product_option_translations (product_option_id, locale_code, title) 
		Values(?, ?, ?)',
		id_bin, p.locale_code, p.title)!
	tx.commit()!
}

fn (mut app App) delete_product_option_translation(id string, locale_code string) ! {
	id_bin := id_to_bin(id)!
	mut tx := app.start_transaction()!
	tx.execute('UPDATE product_option_translations SET deleted_at = CURRENT_TIMESTAMP 
		WHERE product_option_id = ? AND locale_code = ?',
		id_bin, locale_code)!
	tx.commit()!
}
