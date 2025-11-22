module peony

import veb

// lists category
@['/store/categories'; get]
pub fn (mut app App) store_product_category_list(mut ctx Context) veb.Result {
	query_params := extract_product_category_list_request_query(ctx.query)
	p := hygienise_product_category_list_request_query(query_params) or {
		if err is InternalError {
			return handle_error_400(mut ctx, err.message, err.details)
		}
		return handle_error_unhandled(mut ctx, err.msg(), 'hygienise_product_category_list_request_query')
	}

	return conduit_category_list(mut app, mut ctx, p)
}

// get a category by its id
@['/store/categories/:category_id'; get]
pub fn (mut app App) store_product_category_get(mut ctx Context, product_category_id string) veb.Result {
	product_category_id_bin := id_string_to_bin(product_category_id) or {
		return handle_error_400(mut ctx, error_id_invalid, 'product_category_id')
	}

	query_params := extract_product_category_get_request_params(ctx.query)

	p := hygienise_product_category_get_request_query(query_params, product_category_id_bin) or {
		if err is InternalError {
			return handle_suite_error(mut ctx, err)
		}
		return handle_error_unhandled(mut ctx, err.msg(), 'hygienise_product_category_list_request_query')
	}

	return conduit_category_get_store(mut app, mut ctx, p)
}
