module peony

import veb
import einar_hjortdal.firebird
import internal.common
import internal.conduit
import internal.errors

// lists category
// TODO cache
@['/store/categories'; get]
pub fn (mut app App) store_category_list(mut ctx Context) veb.Result {
	lctx := app.get_locale_context(ctx.query) or { return ctx.handle_error(err) }
	p := hygienise_category_list_query_params_store(ctx.query) or { return ctx.handle_error(err) }

	data := app.with_rollback(fn [p] (mut tx firebird.ClientTransaction) !conduit.List[conduit.Category] {
		return conduit.category_list(mut tx, p)
	}) or { return ctx.handle_error(err) }

	return ctx.handle_ok(CategoryResponseStoreListEnvelope{
		categories: format_category_response_list_store(data.items, lctx)
		count:      data.count
		fetch:      p.fetch
		offset:     p.offset
	})
}

// get a category by its id
// TODO cache
@['/store/categories/:category_id'; get]
pub fn (mut app App) store_category_get(mut ctx Context, category_id string) veb.Result {
	lctx := app.get_locale_context(ctx.query) or { return ctx.handle_error(err) }
	parsed_category_id := common.id_from_string(category_id) or {
		return ctx.handle_error(errors.bad_request(errors.id_invalid, 'category_id'))
	}

	category := app.with_rollback(fn [parsed_category_id] (mut tx firebird.ClientTransaction) !conduit.Category {
		return conduit.category_get(mut tx, parsed_category_id)
	}) or { return ctx.handle_error(err) }

	return ctx.handle_ok(CategoryResponseStoreEnvelope{
		category: format_category_response_store(category, lctx)
	})
}
