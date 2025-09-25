module peony

import veb

// lists regions
@['/admin/regions'; get]
pub fn (mut app App) store_regions_get(mut ctx Context) veb.Result {
	// TODO validate params
	p := extract_retrieve_regions_params(ctx.query)
	if p.fetch.is_set && p.fetch.v == 0 {
		return handle_fetch_zero(mut ctx)
	}

	return conduit_region_list(mut app, mut ctx, p)
}
