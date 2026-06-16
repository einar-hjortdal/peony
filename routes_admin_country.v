module peony

import veb
import einar_hjortdal.firebird
import internal.conduit

// list countries
@['/admin/countries'; GET]
pub fn (mut app App) admin_countries_list(mut ctx Context) veb.Result {
	p := hygienise_country_list_query(ctx.query) or { return ctx.handle_error(err) }

	count, countries := app.with_rollback(fn [p] (mut tx firebird.ClientTransaction) !(i64, []conduit.Country) {
		count := conduit.country_retrieve_count(mut tx, p)!
		if count == 0 {
			return count, []conduit.Country{}
		}

		countries := conduit.country_list(mut tx, p)!
		return count, countries
	}) or { return ctx.handle_error() }

	if count == 0 {
		tx.rollback() or {}
		return ctx.handle_ok(CountryResponseListEnvelope{
			offset: p.offset
			fetch:  p.fetch
		})
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
