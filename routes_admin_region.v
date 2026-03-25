module peony

import veb
import json

// lists regions
@['/admin/regions'; get]
pub fn (mut app App) admin_region_list(mut ctx Context) veb.Result {
	p := extract_region_list_request_query(ctx.query)

	ph := hygienise_region_list_request_query(p) or { return ctx.handle_error(err) }

	return conduit_region_list(mut app, mut ctx, ph)
}

// creates a region
@['/admin/regions/'; post]
pub fn (mut app App) admin_regions_post(mut ctx Context) veb.Result {
	data := json.decode(RegionCreateRequest, ctx.req.data) or {
		perr := new_error_bad_request('Could not decode RegionCreateRequest', err.msg())
		return ctx.handle_error(perr)
	}

	if data.country_codes.len == 0 {
		perr := new_error_bad_request(error_empty_object, 'country_codes')
		return ctx.handle_error(perr)
	}

	// TODO validation
	// error if currency_code not in currency table
	// for each country_code error if code not in country table
	// for each country_code error if country already in another region
	// this can be abstracted to a utility function because it would be reused in region update endpoint

	return conduit_region_create(mut app, mut ctx, data)
}

// get a region
// TODO add query params
@['/admin/regions/:region_id'; get]
pub fn (mut app App) admin_region_get(mut ctx Context, region_id string) veb.Result {
	id := id_from_string(region_id) or {
		perr := new_error_bad_request(error_id_invalid, err.msg())
		return ctx.handle_error(perr)
	}
	return conduit_region_get_by_id(mut app, mut ctx, id)
}

// updates a region
@['/admin/regions/:region_id'; post]
pub fn (mut app App) admin_region_update(mut ctx Context, region_id string) veb.Result {
	region_id_bin := id_string_to_bin(region_id) or {
		perr := new_error_bad_request(error_id_invalid, err.msg())
		return ctx.handle_error(perr)
	}

	data := json.decode(RegionUpdateRequest, ctx.req.data) or {
		perr := new_error_bad_request('Could not decode RegionUpdateRequest', err.msg())
		return ctx.handle_error(perr)
	}

	if country_codes := data.country_codes {
		if country_codes.len == 0 {
			perr := new_error_bad_request(error_empty_object, 'country_codes')
			return ctx.handle_error(perr)
		}
	}

	return conduit_region_update(mut app, mut ctx, region_id_bin, data)
}

// deletes a region
@['/admin/regions/:region_id'; delete]
pub fn (mut app App) admin_region_delete(mut ctx Context, region_id string) veb.Result {
	id := id_from_string(region_id) or {
		perr := new_error_bad_request(error_id_invalid, err.msg())
		return ctx.handle_error(perr)
	}

	p := RegionRetriveParams{
		ids:   [id]
		fetch: max_fetch
		order: order_direction_default
	}

	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	store := model_store_retrieve(mut tx) or {
		tx.rollback() or {} // ignore error
		perr := new_error_internal('Could not retrieve store', err.msg())
		return ctx.handle_error(perr)
	}

	count := model_region_retrieve_count(mut tx, p) or {
		tx.rollback() or {} // ignore error
		perr := new_error_internal('Could not retrieve region count', err.msg())
		return ctx.handle_error(perr)
	}

	tx.rollback() or {
		perr := new_error_internal(error_transaction_rollback, err.msg())
		return ctx.handle_error(perr)
	}

	if store.default_region_id == id.string() {
		perr := new_error_bad_request('Could not delete region', 'Cannot delete default region')
		return ctx.handle_error(perr)
	}

	if count == 1 {
		perr := new_error_bad_request('Could not delete region', 'Refusing to delete last region')
		return ctx.handle_error(perr)
	}

	return conduit_region_delete(mut app, mut ctx, id)
}

