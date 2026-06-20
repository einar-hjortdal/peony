module peony

import veb
import einar_hjortdal.firebird
import internal.conduit

// list countries
@['/admin/countries'; GET]
pub fn (mut app App) admin_countries_list(mut ctx Context) veb.Result {
	p := hygienise_country_list_query(ctx.query) or { return ctx.handle_error(err) }

	data := app.with_rollback(fn [p] (mut tx firebird.ClientTransaction) !ListReturn {
		count := conduit.country_list_count(mut tx, p)!
		if count == 0 {
			return ListReturn{}
		}

		countries := conduit.country_list(mut tx, p)!
		return ListReturn{
			count: count
			items: countries
		}
	}) or { return ctx.handle_error(err) }

	if data.count == 0 {
		return ctx.handle_ok(CountryResponseListEnvelope{
			offset: p.offset
			fetch:  p.fetch
		})
	}

	mut external_countries := []CountryResponse{len: data.items.len}
	for i := 0; i < data.items.len; i++ {
		external_countries[i] = format_country_response(data.items[i])
	}

	return ctx.handle_ok(CountryResponseListEnvelope{
		countries: external_countries
		count:     data.count
		offset:    p.offset
		fetch:     p.fetch
	})
}
