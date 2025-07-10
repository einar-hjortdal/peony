module main

import net.http
import json
import veb

// lists products
@['/admin/products'; get]
fn (mut app App) admin_products_get(mut ctx Context) veb.Result {
	p := extract_retrieve_admin_products_params(ctx.query)
	// TODO validate p
	return conduit_products_get_list(mut app, mut ctx, p)
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
	_ := id_string_to_bin(id) or {
		return handle_error(mut ctx, http.Status.bad_request, 'Invalid id', err.msg())
	}

	id_zas := ZeroArrayString{
		v:      [id]
		is_set: true
	}

	p := RetrieveProductParams{
		id: id_zas
	}

	return conduit_products_get_by_id(mut app, mut ctx, p)
}

@['/admin/products/:id'; post]
fn (mut app App) admin_products_id_post(mut ctx Context, id string) veb.Result {
	body := json.decode(ProductData, ctx.req.data) or {
		ctx.res.set_status(http.Status.bad_request)
		return ctx.json(new_peony_error('Could not decode ProductData', err.msg()))
	}

	// TODO validate ids
	// TODO return error when attempting to delete options that are used by some variant
	app.update_product(id, body) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Failed to update product data', err.msg()))
	}

	return ctx.json(new_peony_success())
}

// deletes a product
@['/admin/products/:id'; delete]
fn (mut app App) admin_products_id_delete(mut ctx Context, id string) veb.Result {
	app.delete_product(id) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Failed to delete product', err.msg()))
	}
	return ctx.json(new_peony_success())
}

// creates a product variant
@['/admin/products/:id/variants'; post]
fn (mut app App) admin_products_id_variants_post(mut ctx Context, id string) veb.Result {
	data := json.decode(ProductVariantRequest, ctx.req.data) or {
		ctx.res.set_status(http.Status.bad_request)
		return ctx.json(new_peony_error('Could not decode VariantRequest ', err.msg()))
	}

	// TODO require p.options if options exist for this product
	id_bin := id_string_to_bin(id) or {
		ctx.res.set_status(http.Status.bad_request)
		return ctx.json(new_peony_error('Invalid id ', err.msg()))
	}

	app.create_product_variant(id_bin, data) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Could not create variant ', err.msg()))
	}

	return ctx.json(new_peony_success())
}
