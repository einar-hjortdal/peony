module peony

import veb

fn conduit_region_list(mut app App, mut ctx Context, ph ListRegionParamsHygienised) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	count := model_region_retrieve_count(mut tx, ph) or {
		tx.rollback() or {} // ignore error
		return handle_error_500(mut ctx, 'Failed to retrieve region count', err.msg())
	}

	if count == 0 {
		tx.rollback() or {} // ignore error
		return ctx.json(RegionResponseListEnvelope{
			offset: get_offset_amount(ph.offset)
			fetch:  ph.fetch.v
		})
	}

	mut regions := model_region_retrieve(mut tx, ph) or {
		tx.rollback() or {} // ignore error
		return handle_error_500(mut ctx, 'Failed to retrieve regions', err.msg())
	}

	mut region_ids_bin := [][]u8{len: regions.len}
	for i := 0; i < regions.len; i++ {
		region_ids_bin[i] = regions[i].id_bin
	}

	// TODO fetch taxes: decide whether regions must have at least one tax rate

	mut external_regions := []RegionResponse{len: regions.len}
	for i := 0; i < regions.len; i++ {
		external_regions[i] = format_region_response(regions[i])
	}

	return ctx.json(RegionResponseListEnvelope{
		regions: external_regions
		count:   count
		offset:  get_offset_amount(ph.offset)
		fetch:   ph.fetch.v
	})
}

fn conduit_region_get_by_id(mut app App, mut ctx Context, id_bin []u8) veb.Result {
	internal_region := app.retrieve_region_by_id(id_bin) or {
		return handle_error_400(mut ctx, 'Could not find region', err.msg())
	}

	external_region := format_region_response(internal_region)

	r := RegionResponseEnvelope{
		region: external_region
	}

	return ctx.json(r)
}

fn conduit_region_create(mut app App, mut ctx Context, d RegionCreateRequest) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	do_region_create(mut app, mut tx, d) or {
		tx.rollback() or {} // ignore error
		return handle_error_500(mut ctx, 'Could not create region', err.msg())
	}

	tx.commit() or { return handle_error_500(mut ctx, error_transaction_commit, err.msg()) }

	return success(mut ctx)
}

fn conduit_region_update(mut app App, mut ctx Context, region_id_bin []u8, d RegionUpdateRequest) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	do_region_update(mut app, mut tx, region_id_bin, d) or {
		tx.rollback() or {} // ignore error
		return handle_error_500(mut ctx, 'Could not update region', err.msg())
	}

	tx.commit() or { return handle_error_500(mut ctx, error_transaction_commit, err.msg()) }

	return success(mut ctx)
}
