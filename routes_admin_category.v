module peony

import veb
import einar_hjortdal.firebird
import internal.errors
import internal.conduit

// lists category
@['/admin/categories'; get]
pub fn (mut app App) category_list(mut ctx Context) veb.Result {
	p := hygienise_category_list_request_query(ctx.query) or { return ctx.handle_error(err) }

	data := app.with_rollback(fn [p] (mut tx firebird.ClientTransaction) !ListReturn {
		count := conduit.category_list_count(mut tx, p)!
		if count == 0 {
			return ListReturn{}
		}

		categories := conduit.category_list(mut tx, p)!
		return ListReturn{
			count: count
			items: categories
		}
	}) or { return ctx.handle_error() }

	if data.count == 0 {
		return ctx.handle_ok(CategoryListResponseEnvelope{
			fetch:  p.fetch
			offset: p.offset
		})
	}

	external_categories := []CategoryResponse{len: data.items.len}
	for i := 0; i < data.items.len; i++ {
		external_categories[i] = format_category_response(data.items[i])
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
	p := hygienise_category_create_request(ctx.req.data) or { return ctx.handle_error(perr) }
	category_id := app.gen_id()

	category := app.with_commit(fn [mut app, p, category_id] (mut tx firebird.ClientTransaction) !conduit.Category {
		conduit.category_create(mut tx, mut app.luuid_generator, category_id, p)!
		return conduit.category_get(mut tx, category_id)
	}) or { return ctx.handle_error() }

	return ctx.handle_ok(CategoryResponseEnvelope{
		category: format_category_response(category)
	})
}

// get a category by its id
@['/admin/categories/:category_id'; get]
pub fn (mut app App) category_get(mut ctx Context, category_id string) veb.Result {
	parsed_category_id := id_from_string(category_id) or {
		return ctx.handle_error(errors.bad_request(error_id_invalid, 'category_id'))
	}

	category := app.with_rollback(fn [parsed_category_id] (mut tx firebird.ClientTransaction) !conduit.Category {
		return conduit.category_get(mut tx, parsed_category_id)
	}) or { return ctx.handle_error() }

	return ctx.handle_ok(CategoryResponseEnvelope{
		category: format_category_response(category)
	})
}

// updates a category
@['/admin/categories/:category_id'; post]
pub fn (mut app App) category_update(mut ctx Context, category_id string) veb.Result {
	parsed_category_id := id_from_string(category_id) or {
		return ctx.handle_error(errors.bad_request(error_id_invalid, 'category_id'))
	}

	p := hygienise_category_update_request(ctx.req.data) or { return ctx.handle_error(perr) }

	seos := model_category_seo_retrieve(mut tx, [category_id_bin]) or {
		tx.rollback() or {}
		return ctx.handle_error(errors.internal('Could not retrieve seo', err.msg()))
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
		return ctx.handle_error(errors.internal(error_database_data_malformed,
			'Missing category seo for category with id ${category_id}'))
	}

	seo := seos[0]

	params := conduit.CategoryUpdateData{} // TODO

	category := app.with_commit(fn [parsed_category_id, params] (mut tx firebird.ClientTransaction) !conduit.Category {
		conduit.category_update(mut tx, params)
		return conduit.category_get(mut tx, parsed_category_id)
	}) or { return ctx.handle_error() }

	return ctx.handle_ok(CategoryResponseEnvelope{
		category: format_category_response(category)
	})
}

// deletes a category
@['/admin/categories/:category_id'; delete]
pub fn (mut app App) category_delete(mut ctx Context, category_id string) veb.Result {
	parsed_category_id := is_from_string(category_id) or {
		return ctx.handle_error(errors.bad_request(error_id_invalid, 'category_id'))
	}

	app.with_commit(fn [parsed_category_id] (mut tx firebird.ClientTransaction) !NilReturn {
		conduit.category_delete(mut tx, parsed_category_id)!
		return NilReturn{}
	}) or { return ctx.handle_error() }

	return ctx.handle_deleted()
}
