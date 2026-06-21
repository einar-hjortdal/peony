module peony

import veb
import einar_hjortdal.firebird
import internal.conduit

// lists category
// TODO cache
@['/store/categories'; get]
pub fn (mut app App) store_category_list(mut ctx Context) veb.Result {
	locale_context := hygienise_locale_context_query_params(ctx.query) or {
		return ctx.handle_error(err)
	}

	p := hygienise_category_list_query_params_store(ctx.query) or { return ctx.handle_error(err) }

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
		return ctx.handle_ok(CategoryResponseStoreListEnvelope{
			fetch:  p.fetch
			offset: p.offset
		})
	}

	return ctx.handle_ok(CategoryResponseStoreListEnvelope{
		categories: format_category_response_list_store(data.items, locale_context)
		count:      data.count
		fetch:      p.fetch
		offset:     p.offset
	})
}

// get a category by its id
// TODO cache
@['/store/categories/:category_id'; get]
pub fn (mut app App) store_category_get(mut ctx Context, category_id string) veb.Result {
	locale_context := hygienise_locale_context_query_params(ctx.query) or {
		return ctx.handle_error(err)
	}

	parsed_category_id := id_from_string(category_id) or {
		perr := new_error_bad_request(error_id_invalid, 'category_id')
		return ctx.handle_error(perr)
	}

	category := app.with_rollback(fn [parsed_category_id] (mut tx firebird.ClientTransaction) !conduit.Category {
		return conduit.category_get(mut tx, parsed_category_id)
	}) or { return ctx.handle_error(err) }

	return ctx.handle_ok(CategoryResponseStoreEnvelope{
		category: format_category_response_store(category, locale_context)
	})
}
