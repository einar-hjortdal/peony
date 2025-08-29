module peony

import json
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

// updates a currency
@['/admin/currencies/:code'; post]
pub fn (mut app App) admin_currencies_post(mut ctx Context, code string) veb.Result {
	p := json.decode(NewCurrencyData, ctx.req.data) or {
		return handle_error_400(mut ctx, 'Could not decode NewCurrencyData', err.msg())
	}
	return conduit_currency_update(mut app, mut ctx, code, p)
}
