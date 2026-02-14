module peony

import veb

fn conduit_region_list(mut app App, mut ctx Context, p RegionRetriveParams) veb.Result {
	mut tx := app.start_transaction() or {
		perr := new_error_internal(error_transaction_start, err.msg())
		return ctx.handle_peony_error(perr)
	}

	count := model_region_retrieve_count(mut tx, p) or {
		tx.rollback() or {}
		perr := new_error_internal('Failed to retrieve region count', err.msg())
		return ctx.handle_peony_error(perr)
	}

	if count == 0 {
		tx.rollback() or {
			perr := new_error_internal(error_transaction_rollback, err.msg())
			return ctx.handle_peony_error(perr)
		}
		return ctx.json(RegionResponseListEnvelope{
			offset: p.offset
			fetch:  p.fetch
		})
	}

	mut regions := model_region_retrieve(mut tx, p) or {
		tx.rollback() or {}
		perr := new_error_internal('Failed to retrieve regions', err.msg())
		return ctx.handle_peony_error(perr)
	}

	tx.rollback() or {
		perr := new_error_internal(error_transaction_rollback, err.msg())
		return ctx.handle_peony_error(perr)
	}

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
		perr := new_error_internal(error_transaction_start, err.msg())
		return ctx.handle_peony_error(perr)
	}

	count := model_region_retrieve_count(mut tx, p) or {
		tx.rollback() or {}
		perr := new_error_internal('Failed to retrieve region count', err.msg())
		return ctx.handle_peony_error(perr)
	}

	if count == 0 {
		tx.rollback() or {
			perr := new_error_internal(error_transaction_rollback, err.msg())
			return ctx.handle_peony_error(perr)
		}
		return ctx.json(RegionResponseListEnvelope{
			offset: p.offset
			fetch:  p.fetch
		})
	}
	mut regions := model_region_retrieve(mut tx, p) or {
		tx.rollback() or {}
		perr := new_error_internal('Failed to retrieve regions', err.msg())
		return ctx.handle_peony_error(perr)
	}

	tx.rollback() or {
		perr := new_error_internal(error_transaction_rollback, err.msg())
		return ctx.handle_peony_error(perr)
	}

	return ctx.json(RegionResponseEnvelope{
		region: format_region_response(regions[0])
	})
}

fn conduit_region_create(mut app App, mut ctx Context, d RegionCreateRequest) veb.Result {
	mut tx := app.start_transaction() or {
		perr := new_error_internal(error_transaction_start, err.msg())
		return ctx.handle_peony_error(perr)
	}

	_, region_id_bin := app.new_id()

	model_region_create(mut tx, region_id_bin, d) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not create region', err.msg())
		return ctx.handle_peony_error(perr)
	}

	tx.commit() or {
		perr := new_error_internal(error_transaction_commit, err.msg())
		return ctx.handle_peony_error(perr)
	}

	return success(mut ctx)
}

fn conduit_region_update(mut app App, mut ctx Context, region_id_bin []u8, d RegionUpdateRequest) veb.Result {
	mut tx := app.start_transaction() or {
		perr := new_error_internal(error_transaction_start, err.msg())
		return ctx.handle_peony_error(perr)
	}

	model_region_update(mut tx, region_id_bin, d) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not update region', err.msg())
		return ctx.handle_peony_error(perr)
	}

	tx.commit() or {
		perr := new_error_internal(error_transaction_commit, err.msg())
		return ctx.handle_peony_error(perr)
	}

	return success(mut ctx)
}

fn conduit_region_delete(mut app App, mut ctx Context, region_id_bin []u8) veb.Result {
	mut tx := app.start_transaction() or {
		perr := new_error_internal(error_transaction_start, err.msg())
		return ctx.handle_peony_error(perr)
	}

	model_region_delete(mut tx, region_id_bin) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not delete region', err.msg())
		return ctx.handle_peony_error(perr)
	}

	tx.commit() or {
		perr := new_error_internal(error_transaction_commit, err.msg())
		return ctx.handle_peony_error(perr)
	}

	return success(mut ctx)
}
