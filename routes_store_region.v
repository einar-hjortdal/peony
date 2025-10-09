module peony

import veb

// lists regions
@['/admin/regions'; get]
pub fn (mut app App) store_regions_get(mut ctx Context) veb.Result {
	ph := hygienise_retrieve_regions_params(ctx.query) or {
		if err is InternalError {
			return handle_error_400(mut ctx, err.message, err.details)
		}
		return handle_error_500(mut ctx, 'Unhandled error at hygienise_retrieve_regions_params',
			err.msg())
	}

	if ph.fetch.is_set && ph.fetch.v == 0 {
		return handle_fetch_zero(mut ctx)
	}

	return conduit_region_list(mut app, mut ctx, ph)
}
