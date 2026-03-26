module peony

import veb

@['/store/currencies/'; get]
pub fn (mut app App) store_currencies_get(mut ctx Context) veb.Result {
	p := hygienise_currency_list_query(ctx.query) or { return ctx.handle_error(err) }
	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	count := model_currency_retrieve_count(mut tx, p) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not retrieve currency count', err.msg())
		return ctx.handle_error(perr)
	}

	if count == 0 {
		tx.rollback() or {}
		return ctx.handle_ok(CurrencyResponseListEnvelope{
			offset: p.offset
			fetch:  p.fetch
		})
	}

	currencies := conduit_currency_list(mut app, mut tx, p) or {
		tx.rollback() or {}
		return ctx.handle_error(err)
	}

	tx.rollback() or {
		perr := new_error_internal(error_transaction_rollback, err.msg())
		return ctx.handle_error(perr)
	}

	mut external_currencies := []CurrencyResponse{len: currencies.len}
	for i := 0; i < currencies.len; i++ {
		external_currencies[i] = format_currency_response(currencies[i])
	}

	return ctx.handle_ok(CurrencyResponseListEnvelope{
		currencies: external_currencies
		count:      count
		offset:     p.offset
		fetch:      p.fetch
	})
}

// get currency by code
// TODO cache
@['/store/currencies/:code'; get]
pub fn (mut app App) store_currencies_get_by_code(mut ctx Context, code string) veb.Result {
	if code.len != 3 {
		perr := new_error_bad_request(error_id_invalid, 'currency code too long or too short')
		return ctx.handle_error(perr)
	}

	return conduit_currency_get(mut app, mut ctx, code)
}

