module main

import net.http
import veb
import json

// lists regions
@['/admin/regions'; get]
fn (mut app App) admin_regions_get(mut ctx Context) veb.Result {
	// TODO validate params
	p := extract_retrieve_regions_params(ctx.query)
	return conduit_region_list(mut app, mut ctx, p)
}

// creates a region
@['/admin/regions/'; post]
fn (mut app App) admin_regions_post(mut ctx Context) veb.Result {
	data := json.decode(CreateRegionRequest, ctx.req.data) or {
		ctx.res.set_status(http.Status.bad_request)
		return ctx.json(new_peony_error('Could not decode CreateRegionData', err.msg()))
	}

	_, region_id_bin := app.create_region(data) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Failed to retrieve regions data', err.msg()))
	}

	region := app.retrieve_region_by_id(region_id_bin) or {
		ctx.res.set_status(http.Status.bad_request)
		return ctx.json(new_peony_error('Could not find region', err.msg()))
	}

	return ctx.json(region)
}

// get a region
@['/admin/regions/:region_id'; get]
fn (mut app App) admin_regions_region_id_get(mut ctx Context, region_id string) veb.Result {
	region_id_bin := id_string_to_bin(region_id) or {
		return handle_error(mut ctx, http.Status.bad_request, 'Malformed id', err.msg())
	}

	region := app.retrieve_region_by_id(region_id_bin) or {
		ctx.res.set_status(http.Status.bad_request)
		return ctx.json(new_peony_error('Could not find region', err.msg()))
	}
	return ctx.json(region)
}

// updates a region
@['/admin/regions/:region_id'; get]
fn (mut app App) admin_regions_region_id_post(mut ctx Context, region_id string) veb.Result {
	region_id_bin := id_string_to_bin(region_id) or {
		return handle_error(mut ctx, http.Status.bad_request, 'Malformed id', err.msg())
	}
	return ctx.json('{"TODO"}')
}
