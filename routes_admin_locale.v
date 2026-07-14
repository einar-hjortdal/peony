module peony

import veb
import einar_hjortdal.firebird
import internal.common
import internal.conduit
import internal.errors

// list locales
@['/admin/locales/'; get]
pub fn (mut app App) admin_locales_get(mut ctx Context) veb.Result {
	p := hygienise_retrieve_locale_params(ctx.query) or { return ctx.handle_error(err) }

	data := app.with_rollback(fn [p] (mut tx firebird.ClientTransaction) !conduit.List[conduit.Locale] {
		return conduit.locale_list(mut tx, p)
	}) or { return ctx.handle_error(err) }

	return ctx.handle_ok(LocaleResponseListEnvelope{
		locales: format_locale_response_list(data.items)
		count:   data.count
		offset:  p.offset
		fetch:   p.fetch
	})
}

// get locale by id
@['/admin/locales/:locale_id'; get]
pub fn (mut app App) admin_locales_get_by_id(mut ctx Context, locale_id string) veb.Result {
	parsed_locale_id := common.id_from_string(locale_id) or {
		perr := errors.unprocessable_entity(errors.id_invalid, 'locale_id')
		return ctx.handle_error(perr)
	}

	locale := app.with_rollback(fn [parsed_locale_id] (mut tx firebird.ClientTransaction) !conduit.Locale {
		return conduit.locale_get_by_id(mut tx, parsed_locale_id)
	}) or { return ctx.handle_error(err) }

	return ctx.handle_ok(LocaleResponseEnvelope{
		locale: format_locale_response(locale)
	})
}
