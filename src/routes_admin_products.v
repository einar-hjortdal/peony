module main

import net.http
import json
import veb

// retrieves a list of products
// query parameters:
// locale
// offset
// fetch
// order
@['/admin/products'; get]
fn (mut app App) admin_products_get(mut ctx Context) veb.Result {
	p := ProductParams{
		id:               ctx.query['id'].split(',')
		handle:           ctx.query['handle']
		is_giftcard:      parse_bool(ctx.query['is_giftcard'])
		status:           ctx.query['status']
		collection_id:    ctx.query['collection_id'].split(',')
		type_id:          ctx.query['type_id'].split(',')
		tags:             ctx.query['tags'].split(',')
		title:            ctx.query['title']
		description:      ctx.query['description']
		category_id:      ctx.query['category_id'].split(',')
		sales_channel_id: ctx.query['sales_channel_id'].split(',')
		region_id:        ctx.query['region_id']
		currency_code:    ctx.query['currency_code']
		locale:           ctx.query['locale']
		offset:           ctx.query['offset'].i32()
		fetch:            ctx.query['fetch'].i32()
		order:            ctx.query['order']
	}

	products := app.retrieve_products(p) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error(1, 'Failed to retrieve products data'))
	}

	return ctx.json(products)
}

// create a product
@['/admin/products'; post]
fn (app &App) admin_products_post(mut ctx Context) veb.Result {
	body := json.decode(struct {
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
		variants       []ProductVariant
	}, ctx.req.data) or {
		ctx.res.set_status(http.Status.bad_request)
		return ctx.json(new_peony_error(1, 'Could not decode body data structure'))
	}
	// json body: title required string, (filter by status), id []string, collection_id []string, tags []string,
	// price_list_id []string, sales_channel_id []string, discount_condition_id []string, type_id []string,
	// category_id []string, include_category_children bool, title string, description string, handle string,
	// created_at, updated_at, deleted_at, offset, limit, fields, order
	return ctx.text('ok')
}

// retrieves a list of tags and the amount of times each tag is being used by products
@['/admin/products/tag-usage'; get]
fn (app &App) admin_products_tag_usage_get(mut ctx Context) veb.Result {
	return ctx.text('ok')
}

// creates a product
@['/admin/products/:id'; post]
fn (app &App) admin_products_id_post(mut ctx Context) veb.Result {
	return ctx.text('ok')
}

// deletes a product
@['/admin/products/:id'; delete]
fn (app &App) admin_products_id_delete(mut ctx Context) veb.Result {
	return ctx.text('ok')
}

// adds a product option
@['/admin/products/:id/options'; post]
fn (app &App) admin_products_id_options_post(mut ctx Context) veb.Result {
	return ctx.text('ok')
}

// deletes a product option
@['/admin/products/:id/options'; delete]
fn (app &App) admin_products_id_options_delete(mut ctx Context) veb.Result {
	return ctx.text('ok')
}

// updates a product option
@['/admin/products/:id/options/:opt_id'; post]
fn (app &App) admin_products_id_options_opt_id_post(mut ctx Context) veb.Result {
	return ctx.text('ok')
}

// lists a products variants
@['/admin/products/:id/variants'; get]
fn (app &App) admin_products_id_variants_get(mut ctx Context) veb.Result {
	return ctx.text('ok')
}

// creates a product variant
@['/admin/products/:id/variants'; post]
fn (app &App) admin_products_id_variants_post(mut ctx Context) veb.Result {
	return ctx.text('ok')
}

// updates a product variant
@['/admin/products/:id/variants/:vari_id'; post]
fn (app &App) admin_products_id_variants_vari_id_post(mut ctx Context) veb.Result {
	return ctx.text('ok')
}

// deletes a product variant
@['/admin/products/:id/variants/:vari_id'; delete]
fn (app &App) admin_products_id_variants_vari_id_delete(mut ctx Context) veb.Result {
	return ctx.text('ok')
}
