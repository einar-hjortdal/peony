module peony

import veb
import json

// gets store details
@['/admin/store/'; get]
pub fn (mut app App) admin_store_get(mut ctx Context) veb.Result {
	return conduit_store_get(mut app, mut ctx)
}

// updates store details
@['/admin/store/:store_id'; post]
pub fn (mut app App) admin_store_post(mut ctx Context, store_id string) veb.Result {
	store_id_bin := id_string_to_bin(store_id) or {
		perr := new_error_bad_request(error_id_invalid, 'store_id')
		return ctx.handle_error(perr)
	}

	p := json.decode(StoreUpdateRequest, ctx.req.data) or {
		perr := new_error_bad_request('Could not decode StoreUpdateRequest', err.msg())
		return ctx.handle_error(perr)
	}

	ph := hygienise_store_request(p) or { return ctx.handle_error(err) }

	return conduit_store_update(mut app, mut ctx, store_id_bin, ph)
}
