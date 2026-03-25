module peony

import veb

// list countries
@['/admin/countries'; GET]
pub fn (mut app App) admin_countries_get(mut ctx Context) veb.Result {
	p := hygienise_country_list_query(ctx.query) or { return ctx.handle_error(err) }

	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	count := model_country_retrieve_count(mut tx, p) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not retrieve countries count', err.msg())
		return ctx.handle_error(perr)
	}

	if count == 0 {
		tx.rollback() or {}
		return ctx.handle_ok(CountryResponseListEnvelope{
			offset: p.offset
			fetch:  p.fetch
		})
	}

	countries := conduit_country_list(mut app, mut tx, p) or {
		tx.rollback() or {}
		return ctx.handle_error(err)
	}

	tx.rollback() or {
		perr := new_error_internal(error_transaction_rollback, err.msg())
		return ctx.handle_error(perr)
	}

	mut external_countries := []CountryResponse{len: countries.len}
	for i := 0; i < countries.len; i++ {
		external_countries[i] = format_country_response(countries[i])
	}

	return ctx.handle_ok(CountryResponseListEnvelope{
		countries: external_countries
		count:     count
		offset:    p.offset
		fetch:     p.fetch
	})
}

