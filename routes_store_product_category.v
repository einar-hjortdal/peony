module peony

import veb

// lists product_category
@['/store/product-categories'; get]
pub fn (mut app App) store_product_category_list(mut ctx Context) veb.Result {
	p := extract_retrieve_product_category_params(ctx.query)
	if p.fetch.is_set && p.fetch.v == 0 {
		return handle_fetch_zero(mut ctx)
	}

	ph := hygienise_product_category_params(p) or {
		if err is InternalError {
			return handle_error_400(mut ctx, err.message, err.details)
		}
		return handle_error_500(mut ctx, 'Unhandled error at hygienise_product_category_params',
			err.msg())
	}

	return conduit_product_category_list(mut app, mut ctx, ph)
}
