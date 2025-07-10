module main

import net.http
import veb
import json

// lists product variants
@['/admin/variants'; get]
fn (mut app App) admin_variants_get(mut ctx Context) veb.Result {
	p := extract_retrieve_variant_params(ctx.query)
	variants := app.retrieve_product_variants(p) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Could not retrieve variants ', err.msg()))
	}

	return ctx.json(variants)
}

// gets a product variant
@['/admin/variants/:id'; get]
fn (mut app App) admin_variants_id_get(mut ctx Context, id string) veb.Result {
	variant := app.retrieve_product_variant_by_id(id) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Could not retrieve variant ', err.msg()))
	}
	return ctx.json(variant)
}

// updates a product variant
@['/admin/variants/:id'; post]
fn (mut app App) admin_variants_id_post(mut ctx Context, id string) veb.Result {
	variant_id_bin := id_string_to_bin(id) or {
		return handle_error(mut ctx, http.Status.bad_request, error_invalid_id, err.msg())
	}

	p := json.decode(ProductVariantRequest, ctx.req.data) or {
		ctx.res.set_status(http.Status.bad_request)
		return ctx.json(new_peony_error('Could not decode VariantRequest ', err.msg()))
	}

	return conduit_update_product_variant(mut app, mut ctx, variant_id_bin, p)
}

// gets the available inventory of the product variant
@['/admin/variants/:id/inventory'; get]
fn (mut app App) admin_variants_inventory_get(mut ctx Context, id string) veb.Result {
	return ctx.text('TODO')
}
