module main

import net.http
import veb

fn conduit_region_list(mut app App, mut ctx Context, p ListRegionParams) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error(mut ctx, http.Status.internal_server_error, error_transaction_start,
			err.msg())
	}

	regions := do_retrieve_regions(mut tx, p) or {
		return handle_error(mut ctx, http.Status.internal_server_error, 'Failed to retrieve regions',
			err.msg())
	}

	mut region_ids_bin := [][]u8{len: regions.len}
	for i := 0; i < regions.len; i++ {
		region_ids_bin[i] = regions[i].id_bin
	}

	tax_rate_ids_bin, mapping := do_retrieve_region_tax_rates(mut tx, region_ids_bin) or {
		return handle_error(mut ctx, http.Status.internal_server_error, 'Failed to retrieve region_tax_rate mapping',
			err.msg())
	}

	tax_rates := do_retrieve_tax_rates_by_id(mut tx, tax_rate_ids_bin) or {
		return handle_error(mut ctx, http.Status.internal_server_error, 'Failed to retrieve tax rates',
			err.msg())
	}

	// TODO assign

	tx.rollback() or {
		return handle_error(mut ctx, http.Status.internal_server_error, error_transaction_commit,
			err.msg())
	}

	return ctx.json(regions)
}
