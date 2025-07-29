module peony

import veb

@['/admin/locales/'; get]
fn (mut app App) admin_locales_get(mut ctx Context) veb.Result {
	p := extract_retrieve_locales_params(ctx.query)
	return conduit_locale_get(mut app, mut ctx, p)
}
