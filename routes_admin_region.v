module peony

import veb
import json
import einar_hjortdal.firebird
import internal.conduit
import internal.errors

// lists regions
@['/admin/regions'; get]
pub fn (mut app App) admin_region_list(mut ctx Context) veb.Result {
	p := hygienise_region_list_request_query(ctx.query) or { return ctx.handle_error(err) }

	data := app.with_rollback(fn [p] (mut tx firebird.ClientTransaction) !ListReturn {
		count := conduit.region_list_count(mut tx, p)!
		if count == 0 {
			return ListReturn{}
		}

		regions := conduit.region_list(mut tx, p)!
		return ListReturn{
			count: count
			items: regions
		}
	}) or { return ctx.handle_error(err) }

	if data.count == 0 {
		return ctx.json(RegionResponseListEnvelope{
			offset: p.offset
			fetch:  p.fetch
		})
	}

	return ctx.handle_ok(RegionResponseListEnvelope{
		regions: format_locale_response_list(data.items)
		count:   count
		offset:  p.offset
		fetch:   p.fetch
	})
}

// creates a region
@['/admin/regions/'; post]
pub fn (mut app App) admin_regions_post(mut ctx Context) veb.Result {
	data := json.decode(RegionCreateRequest, ctx.req.data) or {
		return ctx.handle_error(errors.bad_request('Could not decode RegionCreateRequest',
			err.msg()))
	}
	p := data.hygienise() or { return ctx.handle_error(err) }
	region_id := app.gen_id()

	region := app.with_commit(fn [p, region_id] (mut tx firebird.ClientTransaction) !conduit.Region {
		// TODO validation
		// error if currency_code not in currency table
		// for each country_code error if code not in country table
		// for each country_code error if country already in another region
		// this can be abstracted to a utility function because it would be reused in region update endpoint
		conduit.region_create(mut tx, region_id, p)!
		return conduit.region_get_by_id(mut tx, region_id)
	}) or { return ctx.handle_error(err) }

	return ctx.handle_ok(RegionResponseEnvelope{
		region: format_region_response(region)
	})
}

// get a region
// TODO add query params
@['/admin/regions/:region_id'; get]
pub fn (mut app App) admin_region_get(mut ctx Context, region_id string) veb.Result {
	parsed_region_id := id_from_string(region_id) or {
		return ctx.handle_error(errors.bad_request(error_id_invalid, err.msg()))
	}

	region := app.with_rollback(fn [parsed_region_id] (mut tx firebird.ClientTransaction) !conduit.Region {
		return conduit.region_get_by_id(mut tx, region_id)
	}) or { return ctx.handle_error(err) }

	return ctx.handle_ok(RegionResponseEnvelope{
		region: format_region_response(region)
	})
}

// updates a region
@['/admin/regions/:region_id'; post]
pub fn (mut app App) admin_region_update(mut ctx Context, region_id string) veb.Result {
	parsed_region_id := id_from_string(region_id) or {
		return ctx.handle_error(errors.bad_request(error_id_invalid, err.msg()))
	}

	data := json.decode(RegionUpdateRequest, ctx.req.data) or {
		return ctx.handle_error(errors.bad_request('Could not decode RegionUpdateRequest',
			err.msg()))
	}
	p := data.hygienise() or { return ctx.handle_error(err) }

	region := app.with_commit(fn [p, parsed_region_id] (mut tx firebird.ClientTransaction) !conduit.Region {
		// TODO validation
		// error if currency_code not in currency table
		// for each country_code error if code not in country table
		// for each country_code error if country already in another region
		// this can be abstracted to a utility function because it would be reused in region update endpoint
		conduit.region_update(mut tx, region_id, p)!
		return conduit.region_get_by_id(mut tx, region_id)
	}) or { return ctx.handle_error(err) }

	if country_codes := data.country_codes {
		if country_codes.len == 0 {
			perr := errors.bad_request(error_empty_object, 'country_codes')
			return ctx.handle_error(perr)
		}
	}

	return conduit_region_update(mut app, mut ctx, region_id_bin, data)
}

// deletes a region
@['/admin/regions/:region_id'; delete]
pub fn (mut app App) admin_region_delete(mut ctx Context, region_id string) veb.Result {
	parsed_region_id := id_from_string(region_id) or {
		return ctx.handle_error(errors.bad_request(error_id_invalid, err.msg()))
	}

	p := RegionRetriveParams{
		ids:   [id]
		fetch: max_fetch
		order: order_default
	}

	app.with_commit(fn [p, parsed_region_id] (mut tx firebird.ClientTransaction) !NilReturn {
		store := conduit.store_retrieve(mut tx)!

		if store.default_region_id.string() == id.string() {
			return errors.bad_request('Could not delete region', 'Cannot delete default region')
		}

		count := model_region_retrieve_count(mut tx, p) or {
			return errors.internal('Could not retrieve region count', err.msg())
		}

		if count == 1 {
			return errors.bad_request('Could not delete region', 'Refusing to delete last region')
		}

		conduit.region_delete(mut ctx, parsed_region_id)!
		return NilReturn{}
	}) or { return ctx.handle_error(err) }

	return ctx.handle_deleted()
}
