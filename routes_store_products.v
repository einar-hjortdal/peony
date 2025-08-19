module peony

import net.http
import veb

// lists products
@['/store/products'; get]
pub fn (mut app App) store_products_get(mut ctx Context) veb.Result {
	p := extract_retrieve_store_products_params(ctx.query)

	mut cart_id_bin := []u8{}
	if p.cart_id.is_set {
		cart_id_bin = id_string_to_bin(p.cart_id.v) or {
			return handle_error_400(mut ctx, 'Invalid cart id', err.msg())
		}
	}

	mut region_id_bin := []u8{}
	if p.region_id.is_set {
		region_id_bin = id_string_to_bin(p.region_id.v) or {
			return handle_error_400(mut ctx, 'Invalid region_id', err.msg())
		}
	}

	ph := RetrieveProductParamsHygienised{
		region_id:     p.region_id
		region_id_bin: region_id_bin
		cart_id:       p.cart_id
		cart_id_bin:   cart_id_bin
	}

	return conduit_products_get_store(mut app, mut ctx, ph)
}

// get product by id
@['/store/products/:id'; get]
pub fn (mut app App) store_products_get_by_id(mut ctx Context, id string) veb.Result {
	id_bin := id_string_to_bin(id) or { return handle_error_400(mut ctx, 'Invalid id', err.msg()) }

	p := extract_retrieve_store_products_by_id_params(ctx.query, id)

	mut cart_id_bin := []u8{}
	if p.cart_id.is_set {
		cart_id_bin = id_string_to_bin(p.cart_id.v) or {
			return handle_error_400(mut ctx, 'Invalid cart id', err.msg())
		}
	}

	mut region_id_bin := []u8{}
	if p.region_id.is_set {
		region_id_bin = id_string_to_bin(p.region_id.v) or {
			return handle_error_400(mut ctx, 'Invalid region_id', err.msg())
		}
	}

	ph := RetrieveProductParamsHygienised{
		ids:           p.ids
		ids_bin:       [id_bin]
		region_id:     p.region_id
		region_id_bin: region_id_bin
		cart_id:       p.cart_id
		cart_id_bin:   cart_id_bin
	}

	return conduit_products_get_by_id_store(mut app, mut ctx, ph)
}
