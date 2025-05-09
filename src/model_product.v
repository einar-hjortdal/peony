module main

import arrays
import einar_hjortdal.firebird

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
	id, _ := v[0].get_string()!
	created_at, _ := v[1].get_date_time()!
	updated_at, _ := v[2].get_date_time()!
	deleted_at, _ := v[3].get_date_time()!
	handle, _ := v[4].get_string()!
	is_giftcard, _ := v[5].get_bool()!
	status, _ := v[6].get_string()!
	thumbnail, _ := v[8].get_string()!
	collection_id, _ := v[9].get_string()!
	type_id, _ := v[10].get_string()!
	discountable, _ := v[11].get_bool()!
	origin_country, _ := v[12].get_string()!
	weight, _ := v[13].get_i32()!
	length, _ := v[14].get_i32()!
	height, _ := v[15].get_i32()!
	width, _ := v[16].get_i32()!
	title, _ := v[17].get_string()!
	subtitle, _ := v[18].get_string()!
	description, _ := v[19].get_string()!

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
	locale           string
	offset           i32
	fetch            i32
	order            string
}

fn build_query_retrieve_products(p ProductParams) (string, []firebird.Value) {
	fetch := i32_or_max(p.fetch)

	base_query := 'SELECT
		UUID_TO_CHAR(p.id),
		p.created_at,
		p.updated_at,
		p.deleted_at,
		p.handle,
		p.is_giftcard,
		p.status,
		p.thumbnail,
		UUID_TO_CHAR(p.collection_id),
		UUID_TO_CHAR(p.type_id),
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

	if p.locale == '' {
		joins += '
			LEFT JOIN store s ON TRUE
			AND pt.locale_code = s.default_locale_code'
	} else {
		conditions += '
		AND pt.locale_code = ?'
		params = arrays.concat(params, p.locale)
	}

	params = arrays.concat(params, p.offset, fetch)

	return '${base_query}${joins}${conditions}${sorting}', params
}

fn (mut app App) retrieve_products(p ProductParams) ![]Product {
	query, params := build_query_retrieve_products(p)
	mut tx := app.fb.start_transaction(firebird.isolation_level_read_commited)!
	data := tx.execute(query, ...params)!
	tx.rollback()!

	mut products := []Product{}
	for i := 0; i < data.rows.len; i++ {
		product := parse_product(data.rows[i].values)!
		products = arrays.concat(products, product)
	}

	return products
}
