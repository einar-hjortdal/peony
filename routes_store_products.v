module main

import net.http
import veb

// lists products
@['/store/products'; get]
fn (mut app App) store_products_get(mut ctx Context) veb.Result {
	p := extract_retrieve_store_products_params(ctx.query)
	return conduit_products_get_list(mut app, mut ctx, p)
}

// get product by id
@['/store/products/:id'; get]
fn (mut app App) store_products_get_by_id(mut ctx Context, id string) veb.Result {
	_ := id_string_to_bin(id) or {
		return handle_error(mut ctx, http.Status.bad_request, 'Invalid id', err.msg())
	}

	p := extract_retrieve_store_products_by_id_params(ctx.query, id)
	return conduit_products_get_by_id(mut app, mut ctx, p)
}
