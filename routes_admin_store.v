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

	p := json.decode(NewStoreData, ctx.req.data) or {
		ctx.res.set_status(http.Status.bad_request)
		return ctx.json(new_peony_error('Could not decode NewStoreData', err.msg()))
	}

	app.update_store_data(id_bin, p) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Could not update store data', err.msg()))
	}

	return app.admin_store_get(mut ctx)
}
