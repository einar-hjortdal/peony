module peony

import veb
import json

// lists category
@['/admin/categories'; get]
pub fn (mut app App) admin_category_list(mut ctx Context) veb.Result {
	query_params := extract_category_list_request_query(ctx.query)

	p := hygienise_category_list_request_query(query_params) or { return ctx.handle_error(err) }

	return conduit_category_list(mut app, mut ctx, p)
}

// creates category
@['/admin/categories'; post]
pub fn (mut app App) admin_category_create(mut ctx Context) veb.Result {
	p := json.decode(CategoryCreateRequest, ctx.req.data) or {
		perr := new_error_bad_request('Could not decode CategoryCreateRequest', err.msg())
		return ctx.handle_peony_error(perr)
	}

	ph := p.hygienise() or { return ctx.handle_error(err) }

	if translations := ph.translations {
		for i := 0; i < translations.len; i++ {
			// TODO verify default locale is in array
			// TODO verify locale_ids exist
		}
	}

	return conduit_category_create(mut app, mut ctx, ph)
}

// get a category by its id
@['/admin/categories/:category_id'; get]
pub fn (mut app App) admin_category_get(mut ctx Context, category_id string) veb.Result {
	category_id_bin := id_string_to_bin(category_id) or {
		perr := new_error_bad_request(error_id_invalid, 'category_id')
		return ctx.handle_peony_error(perr)
	}

	query_params := extract_category_get_request_params(ctx.query)

	p := hygienise_category_get_request_query(query_params, category_id_bin) or {
		if err is PeonyError {
			return ctx.handle_peony_error(err)
		}
		return ctx.handle_unhandled_error('hygienise_category_list_request_query', err.msg())
	}

	return conduit_category_get(mut app, mut ctx, p)
}

// updates a category
@['/admin/categories/:category_id'; post]
pub fn (mut app App) admin_category_update(mut ctx Context, category_id string) veb.Result {
	category_id_bin := id_string_to_bin(category_id) or {
		perr := new_error_bad_request(error_id_invalid, 'category_id')
		return ctx.handle_peony_error(perr)
	}

	p := json.decode(CategoryUpdateRequest, ctx.req.data) or {
		perr := new_error_bad_request('Could not decode CategoryUpdateRequest', err.msg())
		return ctx.handle_peony_error(perr)
	}

	ph := p.hygienise() or {
		if err is PeonyError {
			return ctx.handle_peony_error(err)
		}
		return ctx.handle_unhandled_error('CategoryUpdateRequest.hygienise', err.msg())
	}

	mut tx := app.start_transaction() or {
		perr := new_error_internal(error_transaction_start, err.msg())
		return ctx.handle_peony_error(perr)
	}

	seo := model_category_seo_retrieve(mut tx, [category_id_bin]) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not retrieve seo', err.msg())
		return ctx.handle_peony_error(perr)
	}

	if _ := ph.parent_category_id {
		// TODO verify ph.parent_category_id exists
	}

	if _ := ph.translations {
		// TODO verify ids
	}

	if _ := ph.seo {
		// TODO verify seo_id exists
		// TODO verify seo_id belongs to category_id
		// TODO verify all locale_id exist
	}

	if seo.len == 0 {
		perr := new_error_internal(error_database_data_malformed, 'Missing category seo for category with id ${category_id}')
		return ctx.handle_peony_error(perr)
	}

	category_seo := seo[0]

	tx.rollback() or {
		perr := new_error_internal(error_transaction_rollback, err.msg())
		return ctx.handle_peony_error(perr)
	}

	return conduit_category_update(mut app, mut ctx, category_id_bin, category_seo.id_bin,
		ph)
}

// deletes a category
@['/admin/categories/:category_id'; delete]
pub fn (mut app App) admin_category_delete(mut ctx Context, category_id string) veb.Result {
	category_id_bin := id_string_to_bin(category_id) or {
		perr := new_error_bad_request(error_id_invalid, 'category_id')
		return ctx.handle_peony_error(perr)
	}

	return conduit_category_delete(mut app, mut ctx, category_id_bin)
}
