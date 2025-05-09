module main

import net.http
import veb
import json

// lists regions
@['/admin/regions'; get]
fn (mut app App) admin_regions_get(mut ctx Context) veb.Result {
	p := ListRegionParams{
		name:   ctx.query['name']
		offset: ctx.query['offset'].i32()
		fetch:  ctx.query['fetch'].i32()
		order:  ctx.query['order']
	}
	regions := app.list_regions(p) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error(1, 'Failed to retrieve regions data'))
	}

	return ctx.json(regions)
}

@['/admin/regions/'; post]
fn (mut app App) admin_regions_post(mut ctx Context) veb.Result {
	data := json.decode(CreateRegionData, ctx.req.data) or {
		ctx.res.set_status(http.Status.bad_request)
		return ctx.json(new_peony_error(1, 'Could not decode CreateRegionData'))
	}

	region_id := app.create_region(data) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error(1, 'Failed to retrieve regions data'))
	}

	return app.admin_regions_region_id_get(mut ctx, region_id)
}

// get a region
@['/admin/regions/:region_id'; get]
fn (mut app App) admin_regions_region_id_get(mut ctx Context, region_id string) veb.Result {
	region := app.retrieve_region_by_id(region_id) or {
		ctx.res.set_status(http.Status.bad_request)
		return ctx.json(new_peony_error(1, 'Could not find region'))
	}
	return ctx.json(region)
}

// add a country to a region
@['/admin/regions/:region_id/countries/:country_id'; post]
fn (mut app App) admin_regions_region_id_countries_post(mut ctx Context, region_id string, country_id string) veb.Result {
	app.add_country(country_id, region_id) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error(1, 'Failed to add country to region'))
	}

	return app.admin_regions_region_id_get(mut ctx, region_id)
}

// remove a country from a region
@['/admin/regions/:region_id/countries/:country_id'; delete]
fn (mut app App) admin_regions_region_id_countries_delete(mut ctx Context, region_id string, country_id string) veb.Result {
	app.remove_country(country_id, region_id) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error(1, 'Failed to add country to region'))
	}

	return app.admin_regions_region_id_get(mut ctx, region_id)
}
