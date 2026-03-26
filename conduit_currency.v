module peony

import veb
import einar_hjortdal.firebird

fn conduit_currency_list(mut app App, mut tx firebird.Transaction, p CurrencyRetrieveParams) ![]Currency {
	currencies := model_currency_retrieve(mut tx, p) or {
		return new_error_internal('Could not retrieve currencies from database', err.msg())
	}

	return currencies
}

fn conduit_currency_get(mut app App, mut ctx Context, code string) veb.Result {
	p := CurrencyRetrieveParams{
		codes:  [code]
		offset: offset_default
		fetch:  1
		order:  order_direction_default
	}

	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	count := model_currency_retrieve_count(mut tx, p) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not retrieve currency count', err.msg())
		return ctx.handle_error(perr)
	}

	if count == 0 {
		tx.rollback() or {
			perr := new_error_internal(error_transaction_rollback, err.msg())
			return ctx.handle_error(perr)
		}
		perr := new_error_not_found('No currency exists with the given code', 'count == 0')
		return ctx.handle_error(perr)
	}

	currencies := model_currency_retrieve(mut tx, p) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not retrieve currencies from database', err.msg())
		return ctx.handle_error(perr)
	}

	tx.rollback() or {
		perr := new_error_internal(error_transaction_rollback, err.msg())
		return ctx.handle_error(perr)
	}

	external_currency := format_currency_response(currencies[0])

	return ctx.json(CurrencyResponseEnvelope{
		currency: external_currency
	})
}

