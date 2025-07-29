module peony

import json
import net.http
import veb

// lists currencies
// query parameters:
// code
// offset
// fetch
@['/admin/currencies/'; get]
pub fn (mut app App) admin_currencies_get(mut ctx Context) veb.Result {
	p := extract_retrieve_currencies_params(ctx.query)
	return conduit_currency_get(mut app, mut ctx, p)
}

// updates a currency
@['/admin/currencies/:code'; post]
pub fn (mut app App) admin_currencies_post(mut ctx Context, code string) veb.Result {
	p := json.decode(NewCurrencyData, ctx.req.data) or {
		ctx.res.set_status(http.Status.bad_request)
		return ctx.json(new_peony_error('Could not decode NewCurrencyData', err.msg()))
	}
	return conduit_currency_update(mut app, mut ctx, code, p)
}
