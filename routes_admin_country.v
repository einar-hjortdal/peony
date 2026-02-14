module peony

import veb

// list countries
@['/admin/countries'; GET]
pub fn (mut app App) admin_countries_get(mut ctx Context) veb.Result {
	p := extract_retrieve_countries_params(ctx.query)
	if p.fetch.is_set && p.fetch.v == 0 {
		err := new_error_fetch_zero()
		return ctx.handle_error(err)
	}

	return conduit_country_get(mut app, mut ctx, p)
}
