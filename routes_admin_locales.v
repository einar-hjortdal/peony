module peony

import net.http
import veb

@['/admin/locales/'; get]
fn (mut app App) admin_locales_get(mut ctx Context) veb.Result {
	p := extract_retrieve_locales_params(ctx.query)
	internal_locales, count := app.retrieve_locales(p) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Could not retrieve locales from database', err.msg()))
	}

	mut external_locales := []LocaleResponse{len: internal_locales.len}
	for i := 0; i < internal_locales.len; i++ {
		external_locales[i] = format_locale_response(internal_locales[i])
	}

	r := ListResponse{
		items:  external_locales
		count:  count
		offset: get_offset_amount(p.offset)
		fetch:  get_fetch_amount(p.fetch)
	}
	return ctx.json(r)
}
