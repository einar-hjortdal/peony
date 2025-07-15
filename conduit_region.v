module main

import net.http
import veb

fn conduit_region_list(mut app App, mut ctx Context, p ListRegionParams) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error(mut ctx, http.Status.internal_server_error, error_transaction_start,
			err.msg())
	}

	mut regions := do_retrieve_regions(mut tx, p) or {
		tx.rollback() or {} // ignore error
		return handle_error(mut ctx, http.Status.internal_server_error, 'Failed to retrieve regions',
			err.msg())
	}

	mut region_ids_bin := [][]u8{len: regions.len}
	for i := 0; i < regions.len; i++ {
		region_ids_bin[i] = regions[i].id_bin
	}

	tax_rate_ids_bin, region_to_tax_rate_id_map := do_retrieve_region_tax_rates(mut tx,
		region_ids_bin) or {
		tx.rollback() or {} // ignore error
		return handle_error(mut ctx, http.Status.internal_server_error, 'Failed to retrieve region_tax_rate mapping',
			err.msg())
	}

	tax_rates := do_retrieve_tax_rates_by_id(mut tx, tax_rate_ids_bin) or {
		tx.rollback() or {} // ignore error
		return handle_error(mut ctx, http.Status.internal_server_error, 'Failed to retrieve tax rates',
			err.msg())
	}

	tx.rollback() or {
		return handle_error(mut ctx, http.Status.internal_server_error, error_transaction_commit,
			err.msg())
	}

	mut tax_rates_map := map[string]TaxRate{}
	for i := 0; i < tax_rates.len; i++ {
		tax_rates_map[tax_rates[i].id] = tax_rates[i]
	}

	mut region_to_tax_rate_map := map[string][]TaxRate{}
	for region_id, region_tax_rate_ids_bin in region_to_tax_rate_id_map {
		mut tr := []TaxRate{len: region_tax_rate_ids_bin.len}
		for i := 0; i < region_tax_rate_ids_bin.len; i++ {
			tax_rate_id := id_bin_to_string(region_tax_rate_ids_bin[i]) or {
				return handle_error(mut ctx, http.Status.internal_server_error, 'Database error',
					'id stored in database is malformed. Manual intervention is required.')
			}
			tr[i] = tax_rates_map[tax_rate_id]
		}
		region_to_tax_rate_map[region_id] = tr
	}

	for i := 0; i < regions.len; i++ {
		regions[i].tax_rates = region_to_tax_rate_map[regions[i].id]
	}

	return ctx.json(regions)
}
