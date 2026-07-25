module peony

import veb
import einar_hjortdal.firebird
import internal.common
import internal.conduit
import internal.errors

// lists regions
@['/admin/regions'; get]
pub fn (mut app App) admin_region_list(mut ctx Context) veb.Result {
	p := hygienise_region_list_request_query(ctx.query) or { return ctx.handle_error(err) }

	data := app.with_rollback(fn [p] (mut tx firebird.ClientTransaction) !conduit.List[conduit.Region] {
		return conduit.region_list(mut tx, p)
	}) or { return ctx.handle_error(err) }

	return ctx.handle_ok(RegionResponseListEnvelope{
		regions: format_region_response_list(data.items)
		count:   data.count
		offset:  p.offset
		fetch:   p.fetch
	})
}

// creates a region
@['/admin/regions/'; post]
pub fn (mut app App) admin_regions_post(mut ctx Context) veb.Result {
	region_id := common.new_id(mut app.luuid_generator)
	p := hygienise_region_create_request(ctx.req.data, region_id) or {
		return ctx.handle_error(err)
	}

	region := app.with_commit(fn [p, region_id] (mut tx firebird.ClientTransaction) !conduit.Region {
		conduit.region_create(mut tx, p)!
		return conduit.region_get(mut tx, region_id)
	}) or { return ctx.handle_error(err) }

	return ctx.handle_created(RegionResponseEnvelope{
		region: format_region_response(region)
	})
}

// get a region
@['/admin/regions/:region_id'; get]
pub fn (mut app App) admin_region_get(mut ctx Context, region_id string) veb.Result {
	parsed_region_id := common.id_from_string(region_id) or {
		return ctx.handle_error(errors.bad_request(errors.id_invalid, err.msg()))
	}

	region := app.with_rollback(fn [parsed_region_id] (mut tx firebird.ClientTransaction) !conduit.Region {
		return conduit.region_get(mut tx, parsed_region_id)
	}) or { return ctx.handle_error(err) }

	return ctx.handle_ok(RegionResponseEnvelope{
		region: format_region_response(region)
	})
}

// updates a region
@['/admin/regions/:region_id'; post]
pub fn (mut app App) admin_region_update(mut ctx Context, region_id string) veb.Result {
	parsed_region_id := common.id_from_string(region_id) or {
		return ctx.handle_error(errors.bad_request(errors.id_invalid, err.msg()))
	}

	p := hygienise_region_update_request(ctx.req.data, parsed_region_id) or {
		return ctx.handle_error(err)
	}

	region := app.with_commit(fn [p] (mut tx firebird.ClientTransaction) !conduit.Region {
		conduit.region_update(mut tx, p)!
		return conduit.region_get(mut tx, p.id)
	}) or { return ctx.handle_error(err) }

	return ctx.handle_ok(RegionResponseEnvelope{
		region: format_region_response(region)
	})
}

// deletes a region
@['/admin/regions/:region_id'; delete]
pub fn (mut app App) admin_region_delete(mut ctx Context, region_id string) veb.Result {
	parsed_region_id := common.id_from_string(region_id) or {
		return ctx.handle_error(errors.bad_request(errors.id_invalid, err.msg()))
	}

	app.with_commit(fn [parsed_region_id] (mut tx firebird.ClientTransaction) !common.Empty {
		conduit.region_delete(mut tx, parsed_region_id)!
		return common.Empty{}
	}) or { return ctx.handle_error(err) }

	return ctx.handle_deleted()
}
