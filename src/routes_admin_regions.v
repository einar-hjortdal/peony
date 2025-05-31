module main

import net.http
import veb
import json

// lists regions
@['/admin/regions'; get]
fn (mut app App) admin_regions_get(mut ctx Context) veb.Result {
	p := extract_retrieve_regions_params(ctx.query)
	regions := app.retrieve_regions(p) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Failed to retrieve regions data', err.msg()))
	}

	return ctx.json(regions)
}

// creates a region
@['/admin/regions/'; post]
fn (mut app App) admin_regions_post(mut ctx Context) veb.Result {
	data := json.decode(CreateRegionData, ctx.req.data) or {
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
		ctx.res.set_status(http.Status.bad_request)
		return ctx.json(new_peony_error('Malformed id', err.msg()))
	}

	region := app.retrieve_region_by_id(region_id_bin) or {
		ctx.res.set_status(http.Status.bad_request)
		return ctx.json(new_peony_error('Could not find region', err.msg()))
	}
	return ctx.json(region)
}

// add a country to a region
@['/admin/regions/:region_id/countries/:country_id'; post]
fn (mut app App) admin_regions_region_id_countries_post(mut ctx Context, region_id string, country_id string) veb.Result {
	app.add_country(country_id, region_id) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Failed to add country to region', err.msg()))
	}

	return app.admin_regions_region_id_get(mut ctx, region_id)
}

// remove a country from a region
@['/admin/regions/:region_id/countries/:country_id'; delete]
fn (mut app App) admin_regions_region_id_countries_delete(mut ctx Context, region_id string, country_id string) veb.Result {
	app.remove_country(country_id, region_id) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Failed to add country to region', err.msg()))
	}

	return app.admin_regions_region_id_get(mut ctx, region_id)
}
