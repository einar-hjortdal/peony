module peony

import veb
import einar_hjortdal.firebird
import internal.conduit
import internal.errors

// list locales
@['/admin/locales/'; get]
pub fn (mut app App) admin_locales_get(mut ctx Context) veb.Result {
	p := hygienise_retrieve_locale_params(ctx.query) or { return ctx.handle_error(err) }

	data := app.with_rollback(fn [p] (mut tx firebird.ClientTransaction) !ListReturn {
		count := conduit.locale_list_count(mut tx, p)!
		if count == 0 {
			return ListReturn{}
		}

		locales := conduit.locale_list(mut tx, p)!
		return ListReturn{
			count: count
			items: locales
		}
	}) or { return ctx.handle_error() }

	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	count := conduit.locale_list_count(mut tx, p) or {
		tx.rollback() or {}
		return ctx.handle_error(err)
	}

	if data.count == 0 {
		return ctx.handle_ok(LocaleResponseListEnvelope{
			offset: p.offset
			fetch:  p.fetch
		})
	}

	mut external_locales := []LocaleResponse{len: data.items.len}
	for i := 0; i < data.items.len; i++ {
		external_locales[i] = format_locale_response(data.items[i])
	}

	return ctx.handle_ok(LocaleResponseListEnvelope{
		locales: external_locales
		count:   count
		offset:  p.offset
		fetch:   p.fetch
	})
}

// get locale by id
@['/admin/locales/:locale_id'; get]
pub fn (mut app App) admin_locales_get_by_id(mut ctx Context, locale_id string) veb.Result {
	parsed_locale_id := id_from_string(locale_id) or {
		perr := errors.unprocessable_entity(error_id_invalid, 'locale_id')
		return ctx.handle_error(perr)
	}

	locale := app.with_rollback(fn [parsed_locale_id] (mut tx firebird.ClientTransaction) !conduit.Locale {
		return conduit.locale_get(mut tx, parsed_locale_id)
	}) or { return ctx.handle_error() }

	return ctx.handle_ok(LocaleResponseEnvelope{
		locale: format_locale_response(locale)
	})
}
