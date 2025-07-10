module main

import veb

// lists products
@['/store/products'; get]
fn (mut app App) store_products_get(mut ctx Context) veb.Result {
	p := extract_retrieve_store_products_params(ctx.query)
	return conduit_products_get(mut app, mut ctx, p)
}
