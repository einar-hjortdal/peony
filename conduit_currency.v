module peony

import veb

fn conduit_currency_get(mut app App, mut ctx Context, p RetrieveCurrenciesParams) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	internal_currencies, count := app.retrieve_currencies(mut tx, p) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve currencies from database',
			err.msg())
	}

	tx.rollback() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }

	mut external_currencies := []CurrencyResponse{len: internal_currencies.len}
	for i := 0; i < internal_currencies.len; i++ {
		external_currencies[i] = format_currency_response(internal_currencies[i])
	}

	r := CurrencyResponseEnvelope{
		currencies: external_currencies
		count:      count
		offset:     get_offset_amount(p.offset)
		fetch:      p.fetch.v
	}
	return ctx.json(r)
}

fn conduit_currency_update(mut app App, mut ctx Context, code string, p NewCurrencyData) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	app.update_currency(mut tx, code, p) or {
		return handle_error_500(mut ctx, 'Could not update currency data', err.msg())
	}

	tx.commit() or { return handle_error_500(mut ctx, error_transaction_commit, err.msg()) }

	return success(mut ctx)
}
