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
		locale_code:      ctx.query['locale_code']
		offset:           ctx.query['offset'].i32()
		fetch:            ctx.query['fetch'].i32()
		order:            ctx.query['order']
	}

	products := app.retrieve_products(p) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Failed to retrieve products data', err.msg()))
	}

	return ctx.json(products)
}

// get a product
@['/admin/products/:id'; get]
fn (mut app App) admin_products_id_get(mut ctx Context, id string) veb.Result {
	locale_code := ctx.query['locale_code']
	p := app.retrieve_product_by_id(id, locale_code) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Failed to retrieve product data', err.msg()))
	}
	return ctx.json(p)
}

// create a product
@['/admin/products'; post]
fn (mut app App) admin_products_post(mut ctx Context) veb.Result {
	body := json.decode(NewProductData, ctx.req.data) or {
		ctx.res.set_status(http.Status.bad_request)
		return ctx.json(new_peony_error('Could not decode body data structure', err.msg()))
	}

	id := app.create_product(body) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Failed to create product', err.msg()))
	}

	return app.admin_products_id_get(mut ctx, id)
}

// retrieves a list of tags and the amount of times each tag is being used by products
@['/admin/products/tag-usage'; get]
fn (app &App) admin_products_tag_usage_get(mut ctx Context) veb.Result {
	return ctx.text('TODO')
}

// deletes a product
@['/admin/products/:id'; delete]
fn (mut app App) admin_products_id_delete(mut ctx Context, id string) veb.Result {
	app.delete_product(id) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Failed to delete product', err.msg()))
	}
	return ctx.text('ok') // TODO better response
}

// adds a product option
@['/admin/products/:id/options'; post]
fn (mut app App) admin_products_id_options_post(mut ctx Context, id string) veb.Result {
	data := json.decode(struct {
		title string
	}, ctx.req.data) or {
		ctx.res.set_status(http.Status.bad_request)
		return ctx.json(new_peony_error('Could not decode body', err.msg()))
	}

	_ := app.create_product_option(id, data.title) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Failed to create product option', err.msg()))
	}

	return ctx.text('ok') // TODO return option?
}

// lists a products variants
@['/admin/products/:id/variants'; get]
fn (mut app App) admin_products_id_variants_get(mut ctx Context, id string) veb.Result {
	return ctx.text('TODO')
}

// creates a product variant
@['/admin/products/:id/variants'; post]
fn (mut app App) admin_products_id_variants_post(mut ctx Context, id string) veb.Result {
	return ctx.text('TODO')
}

// updates a product variant
@['/admin/products/:id/variants/:variant_id'; post]
fn (mut app App) admin_products_id_variants_variant_id_post(mut ctx Context, id string, variant_id string) veb.Result {
	return ctx.text('ok')
}

// deletes a product variant
@['/admin/products/:id/variants/:variant_id'; delete]
fn (mut app App) admin_products_id_variants_variant_id_delete(mut ctx Context, id string, variant_id string) veb.Result {
	return ctx.text('TODO')
}
