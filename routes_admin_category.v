module peony

import veb
import einar_hjortdal.firebird
import internal.errors
import internal.conduit

// lists category
@['/admin/categories'; get]
pub fn (mut app App) category_list(mut ctx Context) veb.Result {
	p := hygienise_category_list_query_params(ctx.query) or { return ctx.handle_error(err) }

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
	}) or { return ctx.handle_error(err) }

	if data.count == 0 {
		return ctx.handle_ok(CategoryResponseListEnvelope{
			fetch:  p.fetch
			offset: p.offset
		})
	}

	return ctx.handle_ok(CategoryResponseListEnvelope{
		categories: format_category_response_list(data.items)
		count:      data.count
		fetch:      p.fetch
		offset:     p.offset
	})
}

// creates category
@['/admin/categories'; post]
pub fn (mut app App) category_create(mut ctx Context) veb.Result {
	category_id := app.gen_id()
	p := hygienise_category_create_request(ctx.req.data, category_id) or {
		return ctx.handle_error(err)
	}

	category := app.with_commit(fn [mut app, p, category_id] (mut tx firebird.ClientTransaction) !conduit.Category {
		conduit.category_create(mut tx, mut app.luuid_generator, p)!
		return conduit.category_get(mut tx, category_id)
	}) or { return ctx.handle_error(err) }

	return ctx.handle_created(CategoryResponseEnvelope{
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
	}) or { return ctx.handle_error(err) }

	return ctx.handle_ok(CategoryResponseEnvelope{
		category: format_category_response(category)
	})
}

// updates a category
// TODO check handle length
@['/admin/categories/:category_id'; post]
pub fn (mut app App) category_update(mut ctx Context, category_id string) veb.Result {
	parsed_category_id := id_from_string(category_id) or {
		return ctx.handle_error(errors.bad_request(error_id_invalid, 'category_id'))
	}

	p := hygienise_category_update_request(ctx.req.data, parsed_category_id) or {
		return ctx.handle_error(err)
	}

	category := app.with_commit(fn [parsed_category_id, p] (mut tx firebird.ClientTransaction) !conduit.Category {
		conduit.category_update(mut tx, p)!
		return conduit.category_get(mut tx, parsed_category_id)
	}) or { return ctx.handle_error(err) }

	return ctx.handle_ok(CategoryResponseEnvelope{
		category: format_category_response(category)
	})
}

// deletes a category
@['/admin/categories/:category_id'; delete]
pub fn (mut app App) category_delete(mut ctx Context, category_id string) veb.Result {
	parsed_category_id := id_from_string(category_id) or {
		return ctx.handle_error(errors.bad_request(error_id_invalid, 'category_id'))
	}

	app.with_commit(fn [parsed_category_id] (mut tx firebird.ClientTransaction) !NilReturn {
		conduit.category_delete(mut tx, parsed_category_id)!
		return NilReturn{}
	}) or { return ctx.handle_error(err) }

	return ctx.handle_deleted()
}
