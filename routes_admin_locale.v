module peony

import veb
import conduit

// list locales
@['/admin/locales/'; get]
pub fn (mut app App) admin_locales_get(mut ctx Context) veb.Result {
	p := hygienise_retrieve_locale_params(ctx.query) or { return ctx.handle_error(err) }

	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	count := conduit.locale_list_count(mut tx, p) or {
		tx.rollback() or {}
		return ctx.handle_error(err)
	}

	if count == 0 {
		return ctx.handle_ok(LocaleResponseListEnvelope{
			offset: p.offset
			fetch:  p.fetch
		})
	}

	locales := conduit.locale_list(mut tx, p) or {
		tx.rollback() or {}
		return ctx.handle_error(err)
	}

	mut external_locales := []LocaleResponse{len: locales.len}
	for i := 0; i < locales.len; i++ {
		external_locales[i] = format_locale_response(locales[i])
	}

	tx.rollback() or {
		perr := new_error_internal(error_transaction_rollback, err.msg())
		return ctx.handle_error(perr)
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
		perr := new_error_unprocessable_entity(error_id_invalid, 'locale_id')
		return ctx.handle_error(perr)
	}

	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	locale := conduit.locale_get(mut tx, parsed_locale_id) or {
		tx.rollback() or {}
		return ctx.handle_error(err)
	}

	tx.rollback() or {}

	return ctx.handle_ok(LocaleResponseEnvelope{
		locale: format_locale_response(locale)
	})
}

