module peony

import veb

// lists product_category
@['/store/product-categories'; get]
pub fn (mut app App) store_product_category_list(mut ctx Context) veb.Result {
	query_params := extract_product_category_list_request_query(ctx.query)
	p := hygienise_product_category_list_request_query(query_params) or {
		if err is InternalError {
			return handle_error_400(mut ctx, err.message, err.details)
		}
		return handle_error_unhandled(mut ctx, err.msg(), 'hygienise_product_category_list_request_query')
	}

	return conduit_product_category_list(mut app, mut ctx, p)
}
