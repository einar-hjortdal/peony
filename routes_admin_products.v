module main

import arrays
import net.http
import json
import veb

// lists products
@['/admin/products'; get]
fn (mut app App) admin_products_get(mut ctx Context) veb.Result {
	p := extract_retrieve_admin_products_params(ctx.query)

	mut ids_bin := [][]u8{}
	if p.ids.is_set {
		for i := 0; i < p.ids.v.len; i++ {
			id_bin := id_string_to_bin(p.ids.v[i]) or {
				return handle_error(mut ctx, http.Status.bad_request, error_invalid_id,
					err.msg())
			}
			ids_bin = arrays.concat(ids_bin, id_bin)
		}
	}

	mut region_id_bin := []u8{}
	if p.region_id.is_set {
		region_id_bin = id_string_to_bin(p.region_id.v) or {
			return handle_error(mut ctx, http.Status.bad_request, 'Invalid region_id',
				err.msg())
		}
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
		offset:        p.offset
		fetch:         p.fetch
		order:         p.order
		cart_id:       p.cart_id
		// cart_id_bin:           p.cart_id_bin
	}

	return conduit_products_get_list(mut app, mut ctx, ph)
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
	id_bin := id_string_to_bin(id) or {
		return handle_error(mut ctx, http.Status.bad_request, error_invalid_id, err.msg())
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
fn (mut app App) admin_products_id_post(mut ctx Context, id string) veb.Result {
	id_bin := id_string_to_bin(id) or {
		return handle_error(mut ctx, http.Status.bad_request, error_invalid_id, err.msg())
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
