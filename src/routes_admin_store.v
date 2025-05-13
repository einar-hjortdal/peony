module main

import net.http
import veb
import json

// gets store details
@['/admin/store/'; get]
fn (mut app App) admin_store_get(mut ctx Context) veb.Result {
	store := app.store_retrieve() or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Failed to retrieve store data', err.msg()))
	}
	return ctx.json(store)
}

// updates store details
@['/admin/store/:id'; post]
fn (mut app App) admin_store_post(mut ctx Context, id string) veb.Result {
	data := json.decode(NewStoreData, ctx.req.data) or {
		ctx.res.set_status(http.Status.bad_request)
		return ctx.json(new_peony_error('Could not decode NewStoreData', err.msg()))
	}

	app.update_store_data(id, data) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Could not update store data', err.msg()))
	}

	updated_data := app.store_retrieve() or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Could not retrieve updated store data', err.msg()))
	}

	return ctx.json(updated_data)
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
