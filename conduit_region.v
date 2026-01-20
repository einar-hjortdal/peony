module peony

import veb

fn conduit_region_list(mut app App, mut ctx Context, p RegionRetriveParams) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	count := model_region_retrieve_count(mut tx, p) or {
		tx.rollback() or {} // ignore error
		return handle_error_500(mut ctx, 'Failed to retrieve region count', err.msg())
	}

	if count == 0 {
		tx.rollback() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }
		return ctx.json(RegionResponseListEnvelope{
			offset: p.offset
			fetch:  p.fetch
		})
	}

	mut regions := model_region_retrieve(mut tx, p) or {
		tx.rollback() or {} // ignore error
		return handle_error_500(mut ctx, 'Failed to retrieve regions', err.msg())
	}

	tx.rollback() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }

	// TODO fetch taxes

	mut external_regions := []RegionResponse{len: regions.len}
	for i := 0; i < regions.len; i++ {
		external_regions[i] = format_region_response(regions[i])
	}

	return ctx.json(RegionResponseListEnvelope{
		regions: external_regions
		count:   count
		offset:  p.offset
		fetch:   p.fetch
	})
}

fn conduit_region_get_by_id(mut app App, mut ctx Context, id_bin []u8) veb.Result {
	p := RegionRetriveParams{
		filter_by_id: true
		ids_bin:      [id_bin]
		fetch:        1
	}

	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	count := model_region_retrieve_count(mut tx, p) or {
		tx.rollback() or {} // ignore error
		return handle_error_500(mut ctx, 'Failed to retrieve region count', err.msg())
	}

	if count == 0 {
		tx.rollback() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }
		return ctx.json(RegionResponseListEnvelope{
			offset: p.offset
			fetch:  p.fetch
		})
	}
	mut regions := model_region_retrieve(mut tx, p) or {
		tx.rollback() or {} // ignore error
		return handle_error_500(mut ctx, 'Failed to retrieve regions', err.msg())
	}

	tx.rollback() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }

	return ctx.json(RegionResponseEnvelope{
		region: format_region_response(regions[0])
	})
}

fn conduit_region_create(mut app App, mut ctx Context, d RegionCreateRequest) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	_, region_id_bin := app.new_id()

	model_region_create(mut tx, region_id_bin, d) or {
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

	model_region_update(mut tx, region_id_bin, d) or {
		tx.rollback() or {} // ignore error
		return handle_error_500(mut ctx, 'Could not update region', err.msg())
	}

	tx.commit() or { return handle_error_500(mut ctx, error_transaction_commit, err.msg()) }

	return success(mut ctx)
}

fn conduit_region_delete(mut app App, mut ctx Context, region_id_bin []u8) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	model_region_delete(mut tx, region_id_bin) or {
		tx.rollback() or {} // ignore error
		return handle_error_500(mut ctx, 'Could not delete region', err.msg())
	}

	tx.commit() or { return handle_error_500(mut ctx, error_transaction_commit, err.msg()) }

	return success(mut ctx)
}
