module peony

import veb

@['/admin/countries'; GET]
fn (mut app App) admin_countries_get(mut ctx Context) veb.Result {
	return conduit_country_get(mut app, mut ctx)
}
