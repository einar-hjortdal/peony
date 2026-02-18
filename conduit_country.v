module peony

import veb

fn conduit_country_get(mut app App, mut ctx Context, p ListCountriesParams) veb.Result {
	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	internal_countries, count := model_country_list(mut tx, p) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not retrieve countries', err.msg())
		return ctx.handle_error(perr)
	}

	tx.rollback() or {
		perr := new_error_internal(error_transaction_rollback, err.msg())
		return ctx.handle_error(perr)
	}

	mut external_countries := []CountryResponse{len: internal_countries.len}
	for i := 0; i < internal_countries.len; i++ {
		external_countries[i] = format_country_response(internal_countries[i]) or {
			perr := new_error_internal('Could not retrieve countries: region_id stored in database is invalid',
				err.msg())
			return ctx.handle_error(perr)
		}
	}

	r := CountryResponseListEnvelope{
		countries: external_countries
		count:     count
		offset:    get_offset_amount(p.offset)
		fetch:     p.fetch.v
	}
	return ctx.json(r)
}
