module main

import json
import net.http
import veb

// lists currencies
// query parameters:
// code
// offset
// limit
@['/admin/currencies/'; get]
fn (app &App) admin_currencies_get(mut ctx Context) veb.Result {
	return ctx.text('ok')
}

// updates a currency
@['/admin/currencies/:id'; post]
fn (mut app App) admin_currencies_post(mut ctx Context, id string) veb.Result {
	data := json.decode(NewCurrencyData, ctx.req.data) or {
		ctx.res.set_status(http.Status.bad_request)
		return ctx.json(new_peony_error(0, 'Could not decode NewCurrencyData'))
	}

	app.update_currency(id, data) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error(0, 'Could not update currency data'))
	}

	updated_data := app.retrieve_currency_by_id(id) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error(0, 'Could not retrieve updated currency data'))
	}

	return ctx.json(updated_data)
}
