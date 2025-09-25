module peony

import veb

// lists products
@['/store/products'; get]
pub fn (mut app App) store_products_get(mut ctx Context) veb.Result {
	p := extract_retrieve_store_products_params(ctx.query)
	if p.fetch.is_set && p.fetch.v == 0 {
		return handle_fetch_zero(mut ctx)
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

	return conduit_products_get_store(mut app, mut ctx, ph)
}

// get product by id
@['/store/products/:id'; get]
pub fn (mut app App) store_products_get_by_id(mut ctx Context, id string) veb.Result {
	id_bin := id_string_to_bin(id) or { return handle_error_400(mut ctx, 'Invalid id', err.msg()) }

	p := extract_retrieve_store_products_by_id_params(ctx.query, id)

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
		ids:           p.ids
		ids_bin:       [id_bin]
		region_id:     p.region_id
		region_id_bin: region_id_bin
		cart_id:       p.cart_id
		cart_id_bin:   cart_id_bin
		locale_id:     p.locale_id
		locale_id_bin: locale_id_bin
	}

	return conduit_products_get_by_id_store(mut app, mut ctx, ph)
}
