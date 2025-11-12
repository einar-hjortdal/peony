module peony

import veb

// lists currencies
// query parameters:
// code
// offset
// fetch
@['/admin/currencies/'; get]
pub fn (mut app App) admin_currencies_get(mut ctx Context) veb.Result {
	p := extract_retrieve_currencies_params(ctx.query)
	if p.fetch.is_set && p.fetch.v == 0 {
		return handle_fetch_zero(mut ctx)
	}

	return conduit_currency_get(mut app, mut ctx, p)
}
