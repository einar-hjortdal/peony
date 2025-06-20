module main

import net.http
import json
import veb

// lists products
@['/admin/products'; get]
fn (mut app App) admin_products_get(mut ctx Context) veb.Result {
	p := extract_retrieve_products_params(ctx.query)

	internal_products, count := app.retrieve_products(p) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Failed to retrieve products data', err.msg()))
	}

	mut external_products := []ProductResponse{len: internal_products.len}
	for i := 0; i < internal_products.len; i++ {
		external_products[i] = format_product_response(internal_products[i])
	}

	r := ListResponse{
		items:  external_products
		count:  count
		offset: get_offset_amount(p.offset)
		fetch:  get_fetch_amount(p.fetch)
	}

	return ctx.json(r)
}

// create a product
@['/admin/products'; post]
fn (mut app App) admin_products_post(mut ctx Context) veb.Result {
	body := json.decode(ProductData, ctx.req.data) or {
		ctx.res.set_status(http.Status.bad_request)
		return ctx.json(new_peony_error('Could not decode ProductData', err.msg()))
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

// get a product
@['/admin/products/:id'; get]
fn (mut app App) admin_products_id_get(mut ctx Context, id string) veb.Result {
	p := app.retrieve_product_by_id(id) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Failed to retrieve product data', err.msg()))
	}
	return ctx.json(p)
}

// updates a product
@['/admin/products/:id'; post]
fn (mut app App) admin_products_id_post(mut ctx Context, id string) veb.Result {
	body := json.decode(ProductData, ctx.req.data) or {
		ctx.res.set_status(http.Status.bad_request)
		return ctx.json(new_peony_error('Could not decode ProductData', err.msg()))
	}

	app.update_product(id, body) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Failed to update product data', err.msg()))
	}

	return ctx.no_content()
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
fn (mut app App) admin_variants_id_post(mut ctx Context, id string, variant_id string) veb.Result {
	data := json.decode(UpdateVariantData, ctx.req.data) or {
		ctx.res.set_status(http.Status.bad_request)
		return ctx.json(new_peony_error('Could not decode UpdateProductVariantData ',
			err.msg()))
	}

	app.update_product_variant(id, data) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Could not update variant ', err.msg()))
	}

	return app.admin_products_id_get(mut ctx, id)
}
