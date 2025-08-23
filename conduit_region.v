module peony

import veb

fn conduit_region_list(mut app App, mut ctx Context, p ListRegionParams) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	mut internal_regions, count := do_retrieve_regions(mut tx, p) or {
		tx.rollback() or {} // ignore error
		return handle_error_500(mut ctx, 'Failed to retrieve regions', err.msg())
	}

	if internal_regions.len == 0 {
		tx.rollback() or {} // ignore error
		r := RegionResponseListEnvelope{
			regions: []RegionResponse{}
			count:   count
			offset:  get_offset_amount(p.offset)
			fetch:   get_fetch_amount(p.fetch)
		}
		return ctx.json(r)
	}

	mut region_ids_bin := [][]u8{len: internal_regions.len}
	for i := 0; i < internal_regions.len; i++ {
		region_ids_bin[i] = internal_regions[i].id_bin
	}

	// TODO consider changing approach, sleect region_id with tax_rate in one query
	tax_rate_ids_bin, region_to_tax_rate_id_map := do_retrieve_region_tax_rates(mut tx,
		region_ids_bin) or {
		tx.rollback() or {} // ignore error
		return handle_error_500(mut ctx, 'Failed to retrieve region_tax_rate mapping',
			err.msg())
	}

	tax_rates := do_retrieve_tax_rates_by_id(mut tx, tax_rate_ids_bin) or {
		tx.rollback() or {} // ignore error
		return handle_error_500(mut ctx, 'Failed to retrieve tax rates', err.msg())
	}

	tx.rollback() or { return handle_error_500(mut ctx, error_transaction_commit, err.msg()) }

	mut tax_rates_map := map[string]TaxRate{}
	for i := 0; i < tax_rates.len; i++ {
		tax_rates_map[tax_rates[i].id] = tax_rates[i]
	}

	mut region_to_tax_rate_map := map[string][]TaxRate{}
	for region_id, region_tax_rate_ids_bin in region_to_tax_rate_id_map {
		mut rates := []TaxRate{len: region_tax_rate_ids_bin.len}
		for i := 0; i < region_tax_rate_ids_bin.len; i++ {
			tax_rate_id := id_bin_to_string(region_tax_rate_ids_bin[i]) or {
				return handle_error_500(mut ctx, 'Database error', 'id stored in database is malformed. Manual intervention is required.')
			}
			rates[i] = tax_rates_map[tax_rate_id]
		}
		region_to_tax_rate_map[region_id] = rates
	}

	for i := 0; i < internal_regions.len; i++ {
		internal_regions[i].tax_rates = region_to_tax_rate_map[internal_regions[i].id]
	}

	mut external_regions := []RegionResponse{len: internal_regions.len}
	for i := 0; i < internal_regions.len; i++ {
		external_regions[i] = foramt_region_response(internal_regions[i])
	}

	r := RegionResponseListEnvelope{
		regions: external_regions
		count:   count
		offset:  get_offset_amount(p.offset)
		fetch:   get_fetch_amount(p.fetch)
	}
	return ctx.json(r)
}

fn conduit_region_get_by_id(mut app App, mut ctx Context, id_bin []u8) veb.Result {
	internal_region := app.retrieve_region_by_id(id_bin) or {
		return handle_error_400(mut ctx, 'Could not find region', err.msg())
	}

	external_region := foramt_region_response(internal_region)

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
