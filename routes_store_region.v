module peony

import veb

// lists regions
// TODO cache
@['/store/regions'; get]
pub fn (mut app App) store_region_list(mut ctx Context) veb.Result {
	p := extract_region_list_request_query(ctx.query)

	ph := hygienise_region_list_request_query(p) or {
		if err is InternalError {
			return handle_error_400(mut ctx, err.message, err.details)
		}
		return handle_error_500(mut ctx, 'Unhandled error at hygienise_region_list_request_query',
			err.msg())
	}

	return conduit_region_list(mut app, mut ctx, ph)
}

// get a region
// TODO cache
@['/store/regions/:region_id'; get]
pub fn (mut app App) store_region_get(mut ctx Context, region_id string) veb.Result {
	id_bin := id_string_to_bin(region_id) or {
		return handle_error_400(mut ctx, error_id_invalid, err.msg())
	}
	return conduit_region_get_by_id(mut app, mut ctx, id_bin)
}
