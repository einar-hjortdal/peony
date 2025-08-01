module peony

import net.http
import json
import veb

// lists products
@['/admin/products'; get]
pub fn (mut app App) admin_products_get(mut ctx Context) veb.Result {
	p := extract_retrieve_admin_products_params(ctx.query)

	ids_bin := zero_array_id_string_to_array_id_bin(p.ids) or {
		return handle_error(mut ctx, http.Status.bad_request, error_id_invalid, err.msg())
	}

	region_id_bin := zero_id_string_to_id_bin(p.region_id) or {
		return handle_error(mut ctx, http.Status.bad_request, 'Invalid region_id', err.msg())
	}

	ph := RetrieveProductParamsHygienised{
		ids:            p.ids
		ids_bin:        ids_bin
		handle:         p.handle
		is_giftcard:    p.is_giftcard
		status:         p.status
		collection_ids: p.collection_ids
		// collection_ids_bin:    p.collection_id_bin
		type_ids: p.type_ids
		// type_ids_bin:          p.type_id_bin
		tag_ids: p.tag_ids
		// tag_ids_bin:           p.tag_id_bin
		title:        p.title
		description:  p.description
		category_ids: p.category_ids
		// category_ids_bin:      p.category_id_bin
		price_list_ids: p.price_list_ids
		// price_list_ids_bin:    p.price_list_id_bin
		sales_channel_ids: p.sales_channel_ids
		// sales_channel_ids_bin: p.sales_channel_id_bin
		region_id:     p.region_id
		region_id_bin: region_id_bin
		currency_code: p.currency_code
		with_deleted:  p.with_deleted
		offset:        p.offset
		fetch:         p.fetch
		order:         p.order
		cart_id:       p.cart_id
		// cart_id_bin:           p.cart_id_bin
	}

	return conduit_products_get(mut app, mut ctx, ph)
}

// create a product
@['/admin/products'; post]
pub fn (mut app App) admin_products_post(mut ctx Context) veb.Result {
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
pub fn (app &App) admin_products_tag_usage_get(mut ctx Context) veb.Result {
	return ctx.text('TODO')
}

// get a product
@['/admin/products/:id'; get]
pub fn (mut app App) admin_products_id_get(mut ctx Context, id string) veb.Result {
	id_bin := id_string_to_bin(id) or {
		return handle_error(mut ctx, http.Status.bad_request, error_id_invalid, err.msg())
	}

	id_zas := ZeroArrayString{
		v:      [id]
		is_set: true
	}

	ph := RetrieveProductParamsHygienised{
		ids:     id_zas
		ids_bin: [id_bin]
	}

	return conduit_products_get_by_id(mut app, mut ctx, ph)
}

@['/admin/products/:id'; post]
pub fn (mut app App) admin_products_id_post(mut ctx Context, id string) veb.Result {
	id_bin := id_string_to_bin(id) or {
		return handle_error(mut ctx, http.Status.bad_request, error_id_invalid, err.msg())
	}

	p := json.decode(ProductData, ctx.req.data) or {
		ctx.res.set_status(http.Status.bad_request)
		return ctx.json(new_peony_error('Could not decode ProductData', err.msg()))
	}

	// TODO validate ProductData ids if any
	return conduit_products_update(mut app, mut ctx, id_bin, p)
}

// deletes a product
@['/admin/products/:id'; delete]
pub fn (mut app App) admin_products_id_delete(mut ctx Context, id string) veb.Result {
	app.delete_product(id) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Failed to delete product', err.msg()))
	}
	return ctx.json(new_peony_success())
}

// creates a product variant
@['/admin/products/:id/variants'; post]
pub fn (mut app App) admin_products_id_variants_post(mut ctx Context, id string) veb.Result {
	data := json.decode(ProductVariantRequest, ctx.req.data) or {
		ctx.res.set_status(http.Status.bad_request)
		return ctx.json(new_peony_error('Could not decode VariantRequest ', err.msg()))
	}

	// TODO require p.options if options exist for this product
	id_bin := id_string_to_bin(id) or {
		return handle_error(mut ctx, http.Status.bad_request, error_id_invalid, err.msg())
	}

	app.create_product_variant(id_bin, data) or {
		return handle_error(mut ctx, http.Status.bad_request, 'Could not create product_variant',
			err.msg())
	}

	return ctx.json(new_peony_success())
}

// creates a product option
@['/admin/products/:id/options'; post]
pub fn (mut app App) admin_products_id_options_post(mut ctx Context, id string) veb.Result {
	id_bin := id_string_to_bin(id) or {
		return handle_error(mut ctx, http.Status.bad_request, error_id_invalid, err.msg())
	}

	p := json.decode(ProductOptionRequest, ctx.req.data) or {
		ctx.res.set_status(http.Status.bad_request)
		return ctx.json(new_peony_error('Could not decode ProductOptionRequest', err.msg()))
	}

	return conduit_product_option_create(mut app, mut ctx, id, id_bin, p)
}

// updates a product option
@['/admin/products/:product_id/options/:option_id'; post]
pub fn (mut app App) admin_update_product_option(mut ctx Context, product_id string, product_option_id string) veb.Result {
	product_id_bin := id_string_to_bin(product_id) or {
		return handle_error(mut ctx, http.Status.bad_request, error_id_invalid, err.msg())
	}

	product_option_id_bin := id_string_to_bin(product_option_id) or {
		return handle_error(mut ctx, http.Status.bad_request, error_id_invalid, err.msg())
	}

	p := json.decode(ProductOptionRequest, ctx.req.data) or {
		ctx.res.set_status(http.Status.bad_request)
		return ctx.json(new_peony_error('Could not decode ProductOptionRequest', err.msg()))
	}

	return conduit_product_option_update(mut app, mut ctx, product_id, product_id_bin,
		product_option_id, product_option_id_bin, p)
}

// creates a product option
@['/admin/products/:product_id/options/:option_id'; delete]
pub fn (mut app App) admin_product_option_delete(mut ctx Context, product_id string, product_option_id string) veb.Result {
	product_id_bin := id_string_to_bin(product_id) or {
		return handle_error(mut ctx, http.Status.bad_request, error_id_invalid, err.msg())
	}

	product_option_id_bin := id_string_to_bin(product_option_id) or {
		return handle_error(mut ctx, http.Status.bad_request, error_id_invalid, err.msg())
	}

	return conduit_product_option_delete(mut app, mut ctx, product_id, product_id_bin,
		product_option_id, product_option_id_bin)
}
