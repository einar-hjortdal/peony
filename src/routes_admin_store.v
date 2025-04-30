module main

import veb

// gets store details
@['/admin/store/'; get]
fn (app &App) admin_store_get(mut ctx Context) veb.Result {
	return ctx.text('ok')
}

// updates store details
@['/admin/store/'; post]
fn (app &App) admin_store_post(mut ctx Context) veb.Result {
	return ctx.text('ok')
}

// adds a currency code
@['/admin/store/currencies/:code'; post]
fn (app &App) admin_store_currencies_code_post(mut ctx Context) veb.Result {
	return ctx.text('ok')
}

// deletes a currency code
@['/admin/store/currencies/:code'; delete]
fn (app &App) admin_store_currencies_code_delete(mut ctx Context) veb.Result {
	return ctx.text('ok')
}
