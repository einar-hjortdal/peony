module peony

import veb
import json

// lists category
@['/admin/categories'; get]
pub fn (mut app App) admin_category_list(mut ctx Context) veb.Result {
	query_params := extract_category_list_request_query(ctx.query)

	p := hygienise_category_list_request_query(query_params) or {
		if err is InternalError {
			return handle_error_400(mut ctx, err.message, err.details)
		}
		return handle_error_500(mut ctx, 'Unhandled error at hygienise_category_params',
			err.msg())
	}

	return conduit_category_list(mut app, mut ctx, p)
}

// creates category
@['/admin/categories'; post]
pub fn (mut app App) admin_category_create(mut ctx Context) veb.Result {
	p := json.decode(CategoryCreateRequest, ctx.req.data) or {
		return handle_error_400(mut ctx, 'Could not decode CategoryCreateRequest', err.msg())
	}

	ph := p.hygienise() or {
		if err is InternalError {
			return handle_error_400(mut ctx, err.message, err.details)
		}
		return handle_error_unhandled(mut ctx, err.msg(), 'CategoryCreateRequest.hygienise')
	}

	for i := 0; i < p.translations.len; i++ {
		// TODO verify default locale is in array
		// TODO verify locale_ids exist
	}

	return conduit_category_create(mut app, mut ctx, ph)
}

// get a category by its id
@['/admin/categories/:category_id'; get]
pub fn (mut app App) admin_category_get(mut ctx Context, category_id string) veb.Result {
	category_id_bin := id_string_to_bin(category_id) or {
		return handle_error_400(mut ctx, error_id_invalid, 'category_id')
	}

	query_params := extract_category_get_request_params(ctx.query)

	p := hygienise_category_get_request_query(query_params, category_id_bin) or {
		if err is InternalError {
			return handle_suite_error(mut ctx, err)
		}
		return handle_error_unhandled(mut ctx, err.msg(), 'hygienise_category_list_request_query')
	}

	return conduit_category_get(mut app, mut ctx, p)
}

// updates a category
@['/admin/categories/:category_id'; post]
pub fn (mut app App) admin_category_update(mut ctx Context, category_id string) veb.Result {
	category_id_bin := id_string_to_bin(category_id) or {
		return handle_error_400(mut ctx, error_id_invalid, 'category_id')
	}

	p := json.decode(CategoryUpdateRequest, ctx.req.data) or {
		return handle_error_400(mut ctx, 'Could not decode CategoryUpdateRequest', err.msg())
	}

	ph := p.hygienise() or {
		if err is InternalError {
			return handle_error_400(mut ctx, err.message, err.details)
		}
		return handle_error_unhandled(mut ctx, err.msg(), 'CategoryUpdateRequest.hygienise')
	}

	if _ := ph.parent_category_id {
		// TODO verify ph.parent_category_id exists
	}

	if _ := ph.translations {
		// TODO verify ids
	}

	if _ := ph.seo_translations {
		// TODO verify ids
	}

	return conduit_category_update(mut app, mut ctx, category_id_bin, ph)
}

// deletes a category
@['/admin/categories/:category_id'; delete]
pub fn (mut app App) admin_category_delete(mut ctx Context, category_id string) veb.Result {
	category_id_bin := id_string_to_bin(category_id) or {
		return handle_error_400(mut ctx, error_id_invalid, 'category_id')
	}

	return conduit_category_delete(mut app, mut ctx, category_id_bin)
}
