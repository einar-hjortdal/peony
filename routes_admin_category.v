module peony

import veb
import json

// lists category
@['/admin/categories'; get]
pub fn (mut app App) category_list(mut ctx Context) veb.Result {
	p := hygienise_category_list_request_query(ctx.query) or { return ctx.handle_error(err) }

	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	count := conduit.category_list_count(mut tx, p) or {
		tx.rollback() or {}
		return ctx.handle_error(err)
	}

	categories := conduit.category_list(mut tx, p) or {
		tx.rollback() or {}
		return ctx.handle_error(err)
	}

	tx.rollback() or {}

	external_categories := []CategoryResponse{len: categories.len}
	for i := 0; i < categories.len; i++ {
		external_categories[i] = foramt_category_response(categories[i])
	}

	return ctx.handle_ok(CategoryListResponseEnvelope{
		categories: external_categories
		count:      count
		fetch:      p.fetch
		offset:     p.offset
	})
}

// creates category
@['/admin/categories'; post]
pub fn (mut app App) category_create(mut ctx Context) veb.Result {
	p := json.decode(CategoryCreateRequest, ctx.req.data) or {
		perr := new_error_bad_request('Could not decode CategoryCreateRequest', err.msg())
		return ctx.handle_error(perr)
	}

	ph := p.hygienise() or { return ctx.handle_error(err) }

	if translations := ph.translations {
		for i := 0; i < translations.len; i++ {
			// TODO verify default locale is in array
			// TODO verify locale_ids exist
		}
	}

	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	conduit.category_create(mut tx, ph) or {
	}

	category := conduit.category_get(mut tx) or {
		tx.rollback() or {}
		return ctx.handle_error(err)
	}

	tx.commit() or {}

	return ctx.handle_ok(CategoryResponseEnvelope{
		category: format_category_response(category)
	})
}

// get a category by its id
@['/admin/categories/:category_id'; get]
pub fn (mut app App) category_get(mut ctx Context, category_id string) veb.Result {
	parsed_category_id := id_from_string(category_id) or {
		perr := new_error_bad_request(error_id_invalid, 'category_id')
		return ctx.handle_error(perr)
	}

	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	category := conduit_category_get(mut tx, parsed_category_id) or {
		tx.rollback() or {}
		return ctx.handle_error(err)
	}

	tx.rollback() or {}

	return ctx.handle_ok(CategoryResponseEnvelope{
		category: format_category_response(category)
	})
}

// updates a category
@['/admin/categories/:category_id'; post]
pub fn (mut app App) category_update(mut ctx Context, category_id string) veb.Result {
	parsed_category_id := id_from_string(category_id) or {
		perr := new_error_bad_request(error_id_invalid, 'category_id')
		return ctx.handle_error(perr)
	}

	p := hygienise_category_update_request(ctx.req.data) or { return ctx.handle_error(perr) }

	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	seos := model_category_seo_retrieve(mut tx, [category_id_bin]) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not retrieve seo', err.msg())
		return ctx.handle_error(perr)
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

	if seos.len == 0 {
		perr := new_error_internal(error_database_data_malformed,
			'Missing category seo for category with id ${category_id}')
		return ctx.handle_error(perr)
	}

	seo := seos[0]

	conduit.category_update(mut tx, conduit.CategoryUpdateData, {
	}) or {
		tx.rollback() or {}
		ctx.handle_error(err)
	}

	category := conduit.category_get(mut tx, parsed_category_id) or {
		tx.rollback() or {}
		ctx.handle_error(err)
	}

	tx.commit() or {}

	return ctx.handle_ok(CategoryResponseEnvelope{
		category: format_category_response(category)
	})
}

// deletes a category
@['/admin/categories/:category_id'; delete]
pub fn (mut app App) category_delete(mut ctx Context, category_id string) veb.Result {
	parsed_category_id := is_from_string(category_id) or {
		return ctx.handle_error(new_error_bad_request(error_id_invalid, 'category_id'))
	}

	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	conduit_category_delete(mut tx, category_id)

	tx.commit() or {}

	return ctx.handle_deleted()
}

