module peony

import veb

// lists regions
@['/admin/regions'; get]
pub fn (mut app App) store_regions_get(mut ctx Context) veb.Result {
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
