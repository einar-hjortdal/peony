module main

import veb

// lists currencies
@['/admin/currencies/'; get]
fn (app App) admin_currencies_get(mut ctx Context) veb.Result {
	// query: code (filter by code), offset, limit
	return ctx.text('ok')
}

// updates a currency
@['/admin/currencies/:code'; post]
fn (app App) admin_currencies_post(mut ctx Context) veb.Result {
	return ctx.text('ok')
}
