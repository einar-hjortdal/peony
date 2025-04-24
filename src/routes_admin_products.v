module main

import veb

// retrieves a list of products
@['/admin/products'; get]
fn (app App) admin_products_get(mut ctx Context) veb.Result {
	// query: status []string (filter by status), id []string, collection_id []string, tags []string,
	// price_list_id []string, sales_channel_id []string, discount_condition_id []string, type_id []string,
	// category_id []string, include_category_children bool, title string, description string, handle string,
	// created_at, updated_at, deleted_at, offset, limit, fields, order
	return ctx.text('ok')
}

struct AdminProductsPost {
	title       string // required
	subtitle    string
	description string
	images      []string
	thumbnail   string
	handle      string
	status      string // draft, proposed, published, rejected
	// product_type  ProductType
	collection_id string
	// tags          []Tag
	// sales_channels []SalesChannel
	// categories []Categories
	// options []Options
	// variants []Variant
	weight         int
	length         int
	height         int
	width          int
	hs_code        string
	origin_country string
	material       []string
}

// create a product
@['/admin/products'; post]
fn (app App) admin_products_post(mut ctx Context) veb.Result {
	// json body: title required string, (filter by status), id []string, collection_id []string, tags []string,
	// price_list_id []string, sales_channel_id []string, discount_condition_id []string, type_id []string,
	// category_id []string, include_category_children bool, title string, description string, handle string,
	// created_at, updated_at, deleted_at, offset, limit, fields, order
	return ctx.text('ok')
}

// retrieves a list of tags and the amount of times each tag is being used by products
@['/admin/products/tag-usage'; get]
fn (app App) admin_products_tag_usage_get(mut ctx Context) veb.Result {
	return ctx.text('ok')
}

// creates a product
@['/admin/products/:id'; post]
fn (app App) admin_products_id_post(mut ctx Context) veb.Result {
	return ctx.text('ok')
}

// deletes a product
@['/admin/products/:id'; delete]
fn (app App) admin_products_id_delete(mut ctx Context) veb.Result {
	return ctx.text('ok')
}

// adds a product option
@['/admin/products/:id/options'; post]
fn (app App) admin_products_id_options_post(mut ctx Context) veb.Result {
	return ctx.text('ok')
}

// deletes a product option
@['/admin/products/:id/options'; delete]
fn (app App) admin_products_id_options_delete(mut ctx Context) veb.Result {
	return ctx.text('ok')
}

// updates a product option
@['/admin/products/:id/options/:opt_id'; post]
fn (app App) admin_products_id_options_opt_id_post(mut ctx Context) veb.Result {
	return ctx.text('ok')
}

// lists a products variants
@['/admin/products/:id/variants'; get]
fn (app App) admin_products_id_variants_get(mut ctx Context) veb.Result {
	return ctx.text('ok')
}

// creates a product variant
@['/admin/products/:id/variants'; post]
fn (app App) admin_products_id_variants_post(mut ctx Context) veb.Result {
	return ctx.text('ok')
}

// updates a product variant
@['/admin/products/:id/variants/:vari_id'; post]
fn (app App) admin_products_id_variants_vari_id_post(mut ctx Context) veb.Result {
	return ctx.text('ok')
}

// deletes a product variant
@['/admin/products/:id/variants/:vari_id'; delete]
fn (app App) admin_products_id_variants_vari_id_delete(mut ctx Context) veb.Result {
	return ctx.text('ok')
}
