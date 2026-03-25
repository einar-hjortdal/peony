module peony

import veb

// lists regions
// TODO cache
@['/store/regions'; get]
pub fn (mut app App) store_region_list(mut ctx Context) veb.Result {
	p := hygienise_region_list_request_query(ctx.query) or { return ctx.handle_error(err) }

	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	count := model_region_retrieve_count(mut tx, p) or {
		tx.rollback() or {}
		perr := new_error_internal('Failed to retrieve region count', err.msg())
		return ctx.handle_error(perr)
	}

	if count == 0 {
		tx.rollback() or {}
		return ctx.json(RegionResponseListEnvelope{
			offset: p.offset
			fetch:  p.fetch
		})
	}

	regions := conduit_region_list(mut app, mut tx, p) or { return ctx.handle_error(err) }

	tx.rollback() or {
		perr := new_error_internal(error_transaction_rollback, err.msg())
		return ctx.handle_error(perr)
	}

	mut external_regions := []RegionResponse{len: regions.len}
	for i := 0; i < regions.len; i++ {
		external_regions[i] = format_region_response(regions[i])
	}

	return ctx.handle_ok(RegionResponseListEnvelope{
		regions: external_regions
		count:   count
		offset:  p.offset
		fetch:   p.fetch
	})
}

// get a region
// TODO cache
@['/store/regions/:region_id'; get]
pub fn (mut app App) store_region_get(mut ctx Context, region_id string) veb.Result {
	id := id_from_string(region_id) or {
		perr := new_error_bad_request(error_id_invalid, 'region_id')
		return ctx.handle_error(perr)
	}
	return conduit_region_get_by_id(mut app, mut ctx, id)
}

