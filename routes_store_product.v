module peony

import veb

// lists products
// TODO price context
// TODO cache
@['/store/products'; get]
pub fn (mut app App) store_products_get(mut ctx Context) veb.Result {
	p := extract_product_list_request_query_store(ctx.query)
	if p.fetch.is_set && p.fetch.v == 0 {
		err := new_error_fetch_zero()
		return ctx.handle_peony_error(err)
	}

	cart_id_bin := zero_id_string_to_id_bin(p.cart_id) or {
		return handle_error_400(mut ctx, 'Invalid cart_id', err.msg())
	}

	region_id_bin := zero_id_string_to_id_bin(p.region_id) or {
		return handle_error_400(mut ctx, 'Invalid region_id', err.msg())
	}

	locale_id_bin := zero_id_string_to_id_bin(p.locale_id) or {
		return handle_error_400(mut ctx, 'Invalid locale_id', err.msg())
	}

	ph := RetrieveProductParamsHygienised{
		region_id:     p.region_id
		region_id_bin: region_id_bin
		cart_id:       p.cart_id
		cart_id_bin:   cart_id_bin
		locale_id:     p.locale_id
		locale_id_bin: locale_id_bin
	}

	return conduit_products_list_store(mut app, mut ctx, ph)
}

// get product by id
// TODO price context
// TODO cache
@['/store/products/:product_id'; get]
pub fn (mut app App) store_products_get_by_id(mut ctx Context, product_id string) veb.Result {
	p := hygienise_product_get_request_query_store(ctx.query, product_id) or {
		return ctx.handle_error(err)
	}

	return conduit_products_get_by_id_store(mut app, mut ctx, p)
}
