module main

import net.http
import veb
import json

// gets store details
@['/admin/store/'; get]
fn (mut app App) admin_store_get(mut ctx Context) veb.Result {
	internal_store := app.store_retrieve() or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Failed to retrieve store data', err.msg()))
	}

	external_store := format_store_response(internal_store)

	return ctx.json(external_store)
}

// updates store details
@['/admin/store/:id'; post]
fn (mut app App) admin_store_post(mut ctx Context, id string) veb.Result {
	id_bin := id_string_to_bin(id) or {
		ctx.res.set_status(http.Status.bad_request)
		return ctx.json(new_peony_error('Malformed id', err.msg()))
	}

	data := json.decode(NewStoreData, ctx.req.data) or {
		ctx.res.set_status(http.Status.bad_request)
		return ctx.json(new_peony_error('Could not decode NewStoreData', err.msg()))
	}

	app.update_store_data(id_bin, data) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Could not update store data', err.msg()))
	}

	return app.admin_store_get(mut ctx)
}

// adds a currency code
@['/admin/store/currencies/:code'; post]
fn (mut app App) admin_store_currencies_code_post(mut ctx Context) veb.Result {
	return ctx.text('ok')
}

// deletes a currency code
@['/admin/store/currencies/:code'; delete]
fn (mut app App) admin_store_currencies_code_delete(mut ctx Context) veb.Result {
	return ctx.text('ok')
}

// adds a locale code
@['/admin/store/locale/:code'; post]
fn (mut app App) admin_store_locale_code_post(mut ctx Context) veb.Result {
	return ctx.text('ok')
}

// deletes a locale code
@['/admin/store/locale/:code'; delete]
fn (mut app App) admin_store_locale_code_delete(mut ctx Context) veb.Result {
	return ctx.text('ok')
}
