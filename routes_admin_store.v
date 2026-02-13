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
		return handle_error_400(mut ctx, error_id_invalid, err.msg())
	}

	p := json.decode(StoreUpdateRequest, ctx.req.data) or {
		return handle_error_400(mut ctx, 'Could not decode StoreUpdateRequest', err.msg())
	}

	ph := hygienise_store_request(p) or {
		if err is PeonyError {
			return handle_error_400(mut ctx, err.message, err.details)
		}
		return ctx.handle_unhandled_error('hygienise_store_request', err.msg())
	}

	return conduit_store_update(mut app, mut ctx, store_id_bin, ph)
}
