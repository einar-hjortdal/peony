module peony

import veb

// list locales
@['/admin/locales/'; get]
pub fn (mut app App) admin_locales_get(mut ctx Context) veb.Result {
	p := hygienise_retrieve_locale_params(ctx.query) or { return ctx.handle_error(err) }

	return conduit_locale_list(mut app, mut ctx, p)
}

// get locale by id
@['/admin/locales/:locale_id'; get]
pub fn (mut app App) admin_locales_get_by_id(mut ctx Context, locale_id string) veb.Result {
	parsed_locale_id := id_from_string(locale_id) or {
		perr := new_error_unprocessable_entity(error_id_invalid, 'locale_id')
		return ctx.handle_error(perr)
	}

	return conduit_locale_get(mut app, mut ctx, LocaleRetrieveParams{
		ids:    [parsed_locale_id]
		offset: offset_default
		fetch:  1
		order:  order_direction_default
	})
}

