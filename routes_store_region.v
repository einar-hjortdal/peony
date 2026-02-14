module peony

import veb

// lists regions
// TODO cache
@['/store/regions'; get]
pub fn (mut app App) store_region_list(mut ctx Context) veb.Result {
	p := extract_region_list_request_query(ctx.query)

	ph := hygienise_region_list_request_query(p) or { return ctx.handle_error(err) }

	return conduit_region_list(mut app, mut ctx, ph)
}

// get a region
// TODO cache
@['/store/regions/:region_id'; get]
pub fn (mut app App) store_region_get(mut ctx Context, region_id string) veb.Result {
	id_bin := id_string_to_bin(region_id) or {
		perr := new_error_bad_request(error_id_invalid, 'region_id')
		return ctx.handle_error(perr)
	}
	return conduit_region_get_by_id(mut app, mut ctx, id_bin)
}
