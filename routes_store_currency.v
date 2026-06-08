module peony

import veb
import conduit

@['/store/currencies/'; get]
pub fn (mut app App) store_currencies_get(mut ctx Context) veb.Result {
	p := hygienise_currency_list_query(ctx.query) or { return ctx.handle_error(err) }

	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	count := conduit.currency_list_count(mut tx, p) or {
		tx.rollback() or {}
		return ctx.handle_error(err)
	}

	if count == 0 {
		tx.rollback() or {}
		return ctx.handle_ok(CurrencyResponseListEnvelope{
			offset: p.offset
			fetch:  p.fetch
		})
	}

	currencies := conduit.currency_list(mut tx, p) or {
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
	if utf8_str_visible_length(code) > length_currency_code {
		perr := new_error_unprocessable_entity(error_field_too_long,
			'currency code must be exactly ${length_currency_code} UTF8 characters long')
		return ctx.handle_error(perr)
	}

	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	currency := conduit.currency_get(mut tx, code) or {
		tx.rollback() or {}
		return ctx.handle_error(err)
	}

	tx.rollback() or {
		perr := new_error_internal(error_transaction_rollback, err.msg())
		return ctx.handle_error(perr)
	}

	return ctx.handle_ok(CurrencyResponseEnvelope{
		currencies: format_currency_response(currency)
	})
}
