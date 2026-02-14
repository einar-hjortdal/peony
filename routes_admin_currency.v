module peony

import veb

// lists currencies
// query parameters:
// code
// offset
// fetch
@['/admin/currencies/'; get]
pub fn (mut app App) admin_currencies_get(mut ctx Context) veb.Result {
	p := extract_retrieve_currencies_params(ctx.query)
	if p.fetch.is_set && p.fetch.v == 0 {
		err := new_error_fetch_zero()
		return ctx.handle_error(err)
	}

	return conduit_currency_list(mut app, mut ctx, p)
}

// get currency by code
@['/admin/currencies/:code'; get]
pub fn (mut app App) admin_currencies_get_by_code(mut ctx Context, code string) veb.Result {
	if code.len != 3 {
		perr := new_error_bad_request(error_id_invalid, 'currency code too long or too short')
		return ctx.handle_error(perr)
	}

	return conduit_currency_get(mut app, mut ctx, code)
}
