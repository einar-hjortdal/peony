module peony

import veb

// lists category
// TODO cache
@['/store/categories'; get]
pub fn (mut app App) store_category_list(mut ctx Context) veb.Result {
	p := hygienise_category_list_request_query(ctx.query) or { return ctx.handle_error(err) }

	return conduit_category_list(mut app, mut ctx, p)
}

// get a category by its id
// TODO cache
@['/store/categories/:category_id'; get]
pub fn (mut app App) store_category_get(mut ctx Context, category_id string) veb.Result {
	parsed_category_id := id_from_string(category_id) or {
		perr := new_error_bad_request(error_id_invalid, 'category_id')
		return ctx.handle_error(perr)
	}

	// TODO context params (locale id, order_id, ...)
	return conduit_category_get_store(mut app, mut ctx, '', CategoryRetrieveParams{
		ids:          [parsed_category_id]
		is_active:    true
		is_internal:  false
		with_deleted: false
		offset:       offset_default
		fetch:        1
		order:        order_default
	})
}

