module peony

import veb

// lists products
// TODO cache
@['/store/products'; get]
pub fn (mut app App) store_products_get(mut ctx Context) veb.Result {
	p := extract_product_list_request_query_store(ctx.query)
	if p.fetch.is_set && p.fetch.v == 0 {
		err := new_error_fetch_zero()
		return ctx.handle_error(err)
	}

	ph := RetrieveProductParamsHygienised{} // TODO rewrite

	price_context := ctx.get_price_context() or { return ctx.handle_error(err) }

	locale_context := hygienise_locale_context_query_params(ctx.query) or {
		return ctx.handle_error(err)
	}

	return conduit_products_list_store(mut app, mut ctx, ph, price_context, locale_context)
}

// get product by id
// TODO cache
@['/store/products/:product_id'; get]
pub fn (mut app App) store_products_get_by_id(mut ctx Context, product_id string) veb.Result {
	p := hygienise_product_get_request_query_store(ctx.query, product_id) or {
		return ctx.handle_error(err)
	}

	price_context := ctx.get_price_context() or { return ctx.handle_error(err) }

	locale_context := hygienise_locale_context_query_params(ctx.query) or {
		return ctx.handle_error(err)
	}

	return conduit_products_get_by_id_store(mut app, mut ctx, p, price_context, locale_context)
}

