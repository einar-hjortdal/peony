module peony

import veb
import json

// lists regions
@['/admin/regions'; get]
pub fn (mut app App) admin_region_list(mut ctx Context) veb.Result {
	p := hygienise_region_list_params(ctx.query) or {
		if err is InternalError {
			return handle_error_400(mut ctx, err.message, err.details)
		}
		return handle_error_500(mut ctx, 'Unhandled error at hygienise_retrieve_regions_params',
			err.msg())
	}

	if p.fetch.is_set && p.fetch.v == 0 {
		return handle_fetch_zero(mut ctx)
	}

	return conduit_region_list(mut app, mut ctx, p)
}

// creates a region
@['/admin/regions/'; post]
pub fn (mut app App) admin_regions_post(mut ctx Context) veb.Result {
	data := json.decode(RegionCreateRequest, ctx.req.data) or {
		return handle_error_400(mut ctx, 'Could not decode RegionCreateRequest', err.msg())
	}

	if data.country_codes.len == 0 {
		return handle_error_400(mut ctx, error_empty_object, 'country_codes')
	}

	// TODO validation
	// error if currency_code not in store currencies
	// error if currency_code not in currency table
	// for each country_code error if code not in country table
	// for each country_code error if country already in another region
	// this can be abstracted to a utility function because it would be reused in region update endpoint

	return conduit_region_create(mut app, mut ctx, data)
}

// get a region
@['/admin/regions/:region_id'; get]
pub fn (mut app App) admin_region_get(mut ctx Context, region_id string) veb.Result {
	id_bin := id_string_to_bin(region_id) or {
		return handle_error_400(mut ctx, error_id_invalid, err.msg())
	}
	return conduit_region_get_by_id(mut app, mut ctx, id_bin)
}

// updates a region
@['/admin/regions/:region_id'; post]
pub fn (mut app App) admin_region_update(mut ctx Context, region_id string) veb.Result {
	region_id_bin := id_string_to_bin(region_id) or {
		return handle_error_400(mut ctx, error_id_invalid, err.msg())
	}

	data := json.decode(RegionUpdateRequest, ctx.req.data) or {
		return handle_error_400(mut ctx, 'Could not decode RegionUpdateRequest', err.msg())
	}

	if country_codes := data.country_codes {
		if country_codes.len == 0 {
			return handle_error_400(mut ctx, error_empty_object, 'country_codes')
		}
	}

	return conduit_region_update(mut app, mut ctx, region_id_bin, data)
}

// deletes a region
@['/admin/regions/:region_id'; delete]
pub fn (mut app App) admin_region_delete(mut ctx Context, region_id string) veb.Result {
	region_id_bin := id_string_to_bin(region_id) or {
		return handle_error_400(mut ctx, error_id_invalid, err.msg())
	}

	p := RegionListParams{}

	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	store := model_store_retrieve(mut tx) or {
		tx.rollback() or {} // ignore error
		return handle_error_500(mut ctx, 'Could not retrieve store', err.msg())
	}

	count := model_region_retrieve_count(mut tx, p) or {
		tx.rollback() or {} // ignore error
		return handle_error_500(mut ctx, 'Could not retrieve region count', err.msg())
	}

	tx.rollback() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }

	if store.default_region_id_bin == region_id_bin {
		return handle_error_400(mut ctx, 'Could not delete region', 'Cannot delete default region')
	}

	if count == 1 {
		return handle_error_400(mut ctx, 'Could not delete region', 'Refusing to delete last region')
	}

	return conduit_region_delete(mut app, mut ctx, region_id_bin)
}
