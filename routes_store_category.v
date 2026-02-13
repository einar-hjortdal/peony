module peony

import veb

// lists category
// TODO cache
@['/store/categories'; get]
pub fn (mut app App) store_category_list(mut ctx Context) veb.Result {
	query_params := extract_category_list_request_query(ctx.query)
	p := hygienise_category_list_request_query(query_params) or {
		if err is PeonyError {
			return handle_error_400(mut ctx, err.message, err.details)
		}
		return ctx.handle_unhandled_error('hygienise_category_list_request_query', err.msg())
	}

	return conduit_category_list(mut app, mut ctx, p)
}

// get a category by its id
// TODO cache
@['/store/categories/:category_id'; get]
pub fn (mut app App) store_category_get(mut ctx Context, category_id string) veb.Result {
	category_id_bin := id_string_to_bin(category_id) or {
		return handle_error_400(mut ctx, error_id_invalid, 'category_id')
	}

	query_params := extract_category_get_request_params(ctx.query)

	p := hygienise_category_get_request_query(query_params, category_id_bin) or {
		if err is PeonyError {
			return ctx.handle_peony_error(err)
		}
		return ctx.handle_unhandled_error('hygienise_category_list_request_query', err.msg())
	}

	return conduit_category_get_store(mut app, mut ctx, query_params.locale_id.v, p)
}
