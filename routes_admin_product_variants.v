module peony

import net.http
import veb

// lists product variants
@['/admin/variants'; get]
pub fn (mut app App) admin_variants_get(mut ctx Context) veb.Result {
	p := extract_retrieve_product_variant_params(ctx.query)

	ids_bin := zero_array_id_string_to_array_id_bin(p.ids) or {
		return handle_error(mut ctx, http.Status.bad_request, error_id_invalid, err.msg())
	}

	product_ids_bin := zero_array_id_string_to_array_id_bin(p.product_ids) or {
		return handle_error(mut ctx, http.Status.bad_request, error_id_invalid, err.msg())
	}

	region_id_bin := zero_id_string_to_id_bin(p.region_id) or {
		return handle_error(mut ctx, http.Status.bad_request, error_id_invalid, err.msg())
	}

	ph := RetrieveProductVariantParamsHygienised{
		ids:                p.ids
		ids_bin:            ids_bin
		product_ids:        p.product_ids
		product_ids_bin:    product_ids_bin
		allow_backorder:    p.allow_backorder
		manage_inventory:   p.manage_inventory
		region_id:          p.region_id
		region_id_bin:      region_id_bin
		currency_code:      p.currency_code
		title:              p.title
		inventory_quantity: p.inventory_quantity
		with_deleted:       p.with_deleted
		offset:             p.offset
		fetch:              p.fetch
		order:              p.order
	}

	return conduit_product_variants_get(mut app, mut ctx, ph)
}

// gets a product variant
@['/admin/variants/:id'; get]
pub fn (mut app App) admin_variants_id_get(mut ctx Context, id string) veb.Result {
	id_bin := id_string_to_bin(id) or {
		return handle_error(mut ctx, http.Status.bad_request, error_id_invalid, err.msg())
	}

	m := {
		'ids': id
	}
	p := extract_retrieve_product_variant_params(m)
	ph := RetrieveProductVariantParamsHygienised{
		ids:     p.ids
		ids_bin: [id_bin]
	}

	return conduit_product_variant_get(mut app, mut ctx, ph)
}

// deletes a product variant
@['/admin/variants/:id'; delete]
pub fn (mut app App) admin_variants_id_delete(mut ctx Context, id string) veb.Result {
	variant_id_bin := id_string_to_bin(id) or {
		return handle_error(mut ctx, http.Status.bad_request, error_id_invalid, err.msg())
	}
	return conduit_product_variant_delete(mut app, mut ctx, variant_id_bin)
}
