module peony

import veb

fn conduit_currency_list(mut app App, mut ctx Context, p RetrieveCurrenciesParams) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	count := model_currency_retrieve_count(mut tx, p) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve currency count', err.msg())
	}

	if count == 0 {
		tx.rollback() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }
		return ctx.json(CurrencyResponseListEnvelope{
			offset: get_offset_amount(p.offset)
			fetch:  p.fetch.v
		})
	}

	currencies := model_currency_retrieve(mut tx, p) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve currencies from database',
			err.msg())
	}

	tx.rollback() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }

	mut external_currencies := []CurrencyResponse{len: currencies.len}
	for i := 0; i < currencies.len; i++ {
		external_currencies[i] = format_currency_response(currencies[i])
	}

	return ctx.json(CurrencyResponseListEnvelope{
		currencies: external_currencies
		count:      count
		offset:     get_offset_amount(p.offset)
		fetch:      p.fetch.v
	})
}

fn conduit_currency_get(mut app App, mut ctx Context, code string) veb.Result {
	p := RetrieveCurrenciesParams{
		codes: ZeroArrayString{
			is_set: true
			v:      [code]
		}
	}

	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	count := model_currency_retrieve_count(mut tx, p) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve currency count', err.msg())
	}

	if count == 0 {
		tx.rollback() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }
		perr := new_error_not_found('No currency exists with the given code', 'count == 0')
		return ctx.handle_peony_error(perr)
	}

	currencies := model_currency_retrieve(mut tx, p) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve currencies from database',
			err.msg())
	}

	tx.rollback() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }

	external_currency := format_currency_response(currencies[0])

	return ctx.json(CurrencyResponseEnvelope{
		currency: external_currency
	})
}
