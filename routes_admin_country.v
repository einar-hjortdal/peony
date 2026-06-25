module peony

import veb
import einar_hjortdal.firebird
import internal.conduit

// list countries
@['/admin/countries'; GET]
pub fn (mut app App) admin_countries_list(mut ctx Context) veb.Result {
	p := hygienise_country_list_query(ctx.query) or { return ctx.handle_error(err) }

	data := app.with_rollback(fn [p] (mut tx firebird.ClientTransaction) !conduit.List[conduit.Country] {
		return conduit.country_list(mut tx, p)
	}) or { return ctx.handle_error(err) }

	return ctx.handle_ok(CountryResponseListEnvelope{
		countries: format_country_response_list(data.items)
		count:     data.count
		offset:    p.offset
		fetch:     p.fetch
	})
}
