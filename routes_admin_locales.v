module peony

import veb

// list locales
@['/admin/locales/'; get]
pub fn (mut app App) admin_locales_get(mut ctx Context) veb.Result {
	p := extract_retrieve_locales_params(ctx.query)
	return conduit_locale_get(mut app, mut ctx, p)
}
