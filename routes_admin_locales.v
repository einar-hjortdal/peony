module main

import net.http
import veb

@['/admin/locales/'; get]
fn (mut app App) admin_locales_get(mut ctx Context) veb.Result {
	p := extract_retrieve_locales_params(ctx.query)
	locales, count := app.retrieve_locales(p) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Could not retrieve locales from database', err.msg()))
	}
	r := ListResponse{
		items:  locales
		count:  count
		offset: get_offset_amount(p.offset)
		fetch:  get_fetch_amount(p.fetch)
	}
	return ctx.json(r)
}
