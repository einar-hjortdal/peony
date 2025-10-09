module peony

import veb
import json

// gets store details
@['/admin/store/'; get]
pub fn (mut app App) admin_store_get(mut ctx Context) veb.Result {
	return conduit_store_get(mut app, mut ctx)
}

// updates store details
@['/admin/store/:id'; post]
pub fn (mut app App) admin_store_post(mut ctx Context, id string) veb.Result {
	id_bin := id_string_to_bin(id) or {
		return handle_error_400(mut ctx, error_id_invalid, err.msg())
	}

	p := json.decode(StoreRequest, ctx.req.data) or {
		return handle_error_400(mut ctx, 'Could not decode NewStoreData', err.msg())
	}

	ph := hygienise_store_request(p) or {
		if err is InternalError {
			return handle_error_400(mut ctx, err.message, err.details)
		}
		return handle_error_500(mut ctx, 'Unhandled error at hygienise_store_request',
			err.msg())
	}

	return conduit_store_update(mut app, mut ctx, id_bin, ph)
}
