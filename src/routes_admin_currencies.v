module main

import json
import net.http
import veb

// lists currencies
// query parameters:
// code
// offset
// fetch
@['/admin/currencies/'; get]
fn (mut app App) admin_currencies_get(mut ctx Context) veb.Result {
	if code := ctx.query['code'] {
		currency := app.retrieve_currency_by_code(code) or {
			ctx.res.set_status(http.Status.internal_server_error)
			return ctx.json(new_peony_error('Could not retrieve currency by code', err.msg()))
		}
		return ctx.json(currency)
	}

	offset := ctx.query['offset'].i32()
	fetch := ctx.query['fetch'].i32()
	currencies := app.retrieve_currencies(offset, fetch) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Could not retrieve currencies from database',
			err.msg()))
	}
	return ctx.json(currencies)
}

// updates a currency
@['/admin/currencies/:code'; post]
fn (mut app App) admin_currencies_post(mut ctx Context, code string) veb.Result {
	data := json.decode(NewCurrencyData, ctx.req.data) or {
		ctx.res.set_status(http.Status.bad_request)
		return ctx.json(new_peony_error('Could not decode NewCurrencyData', err.msg()))
	}

	app.update_currency(code, data) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Could not update currency data', err.msg()))
	}

	updated_data := app.retrieve_currency_by_code(code) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Could not retrieve updated currency data', err.msg()))
	}

	return ctx.json(updated_data)
}
