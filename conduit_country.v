module peony

import veb
import net.http

fn conduit_country_get(mut app App, mut ctx Context, p ListCountriesParams) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	internal_countries, count := model_country_list(mut tx, p) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not get countries', err.msg())
	}

	tx.rollback() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }

	mut external_countries := []CountryResponse{len: internal_countries.len}
	for i := 0; i < internal_countries.len; i++ {
		external_countries[i] = format_country_response(internal_countries[i]) or {
			return handle_error_500(mut ctx, 'Could not retrieve countries: region_id stored in database is invalid',
				err.msg())
		}
	}

	r := CountryResponseListEnvelope{
		countries: external_countries
		count:     count
		offset:    get_offset_amount(p.offset)
		fetch:     get_fetch_amount(p.fetch)
	}

	return ctx.json(r)
}
