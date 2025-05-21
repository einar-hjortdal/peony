module main

import net.http
import veb

// lists product variants
@['/admin/variants'; get]
fn (mut app App) admin_variants_get(mut ctx Context) veb.Result {
	p := RetrieveProductVariantParams{
		id:                 zero_array_string(ctx.query, 'id')
		allow_backorder:    zero_bool(ctx.query, 'allow_backorder')
		manage_inventory:   zero_bool(ctx.query, 'manage_inventory')
		region_id:          zero_string(ctx.query, 'region_id')
		currency_code:      zero_string(ctx.query, 'currency_code')
		title:              zero_string(ctx.query, 'title')
		inventory_quantity: zero_i32(ctx.query, 'inventory_quantity')
		offset:             zero_i32(ctx.query, 'offset')
		fetch:              zero_i32(ctx.query, 'fetch')
		order:              zero_string(ctx.query, 'order')
	}

	variants := app.retrieve_product_variants(p) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Could not retrieve variants ', err.msg()))
	}

	return ctx.json(variants)
}

// lists product variants
@['/admin/variants/:id'; get]
fn (mut app App) admin_variants_id_get(mut ctx Context, id string) veb.Result {
	variant := app.retrieve_product_variant_by_id(id) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Could not retrieve variant ', err.msg()))
	}
	return ctx.json(variant)
}

// gets the available inventory of the product variant
@['/admin/variants/:id/inventory'; get]
fn (mut app App) admin_variants_inventory_get(mut ctx Context, id string) veb.Result {
	return ctx.text('TODO')
}
