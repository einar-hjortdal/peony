module peony

import veb

// list locales
@['/admin/locales/'; get]
pub fn (mut app App) admin_locales_get(mut ctx Context) veb.Result {
	ph := hygienise_retrieve_locale_params(ctx.query) or { return ctx.handle_error(err) }

	if ph.fetch.is_set && ph.fetch.v == 0 {
		err := new_error_fetch_zero()
		return ctx.handle_error(err)
	}

	return conduit_locale_list(mut app, mut ctx, ph)
}

// get locale by id
@['/admin/locales/:locale_id'; get]
pub fn (mut app App) admin_locales_get_by_id(mut ctx Context, locale_id string) veb.Result {
	locale_id_bin := id_string_to_bin(locale_id) or {
		perr := new_error_bad_request(error_id_invalid, 'locale_id')
		return ctx.handle_error(perr)
	}

	ph := LocaleRetrieveParamsHygienised{
		ids:     ZeroArrayString{
			is_set: true
		}
		ids_bin: [locale_id_bin]
	}

	return conduit_locale_get(mut app, mut ctx, ph)
}
