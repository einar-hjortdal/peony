module peony

import veb

// lists products
// TODO cache
@['/store/products'; get]
pub fn (mut app App) store_products_get(mut ctx Context) veb.Result {
	p := extract_product_list_request_query_store(ctx.query)

	price_context := ctx.get_price_context() or { return ctx.handle_error(err) }

	locale_context := hygienise_locale_context_query_params(ctx.query) or {
		return ctx.handle_error(err)
	}

	return conduit_products_list_store(mut app, mut ctx, ProductRetrieveParams{
		fetch:  max_fetch
		offset: 0
		order:  order_direction_default
	}, price_context, locale_context)
}

// get product by id
// TODO cache
@['/store/products/:product_id'; get]
pub fn (mut app App) store_products_get_by_id(mut ctx Context, product_id string) veb.Result {
	parsed_product_id := id_from_string(product_id) or {
		perr := new_error_bad_request(error_id_invalid, 'product_id')
		return ctx.handle_error(perr)
	}

	p := hygienise_product_get_request_query_store(ctx.query, product_id) or {
		return ctx.handle_error(err)
	}

	price_context := ctx.get_price_context() or { return ctx.handle_error(err) }

	locale_context := hygienise_locale_context_query_params(ctx.query) or {
		return ctx.handle_error(err)
	}

	return conduit_products_get_by_id_store(mut app, mut ctx, ProductRetrieveParams{
		ids:    [parsed_product_id]
		fetch:  max_fetch
		offset: 0
		order:  order_direction_default
	}, price_context, locale_context)
}

