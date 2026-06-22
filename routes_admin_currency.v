module peony

import veb
import einar_hjortdal.firebird
import internal.conduit
import internal.errors

@['/admin/currencies/'; get]
pub fn (mut app App) admin_currencies_get(mut ctx Context) veb.Result {
	p := hygienise_currency_list_query(ctx.query) or { return ctx.handle_error(err) }

	data := app.with_rollback(fn [p] (mut tx firebird.ClientTransaction) !ListReturn {
		count := conduit.currency_list_count(mut tx, p)!
		if count == 0 {
			return ListReturn{}
		}

		currencies := conduit.currency_list(mut tx, p)!
		return ListReturn{
			count: count
			items: currencies
		}
	}) or { return ctx.handle_error(err) }

	if data.count == 0 {
		return ctx.handle_ok(CurrencyResponseListEnvelope{
			offset: p.offset
			fetch:  p.fetch
		})
	}

	return ctx.handle_ok(CurrencyResponseListEnvelope{
		currencies: format_currency_list_response(data.items)
		count:      data.count
		offset:     p.offset
		fetch:      p.fetch
	})
}

// get currency by code
@['/admin/currencies/:code'; get]
pub fn (mut app App) admin_currencies_get_by_code(mut ctx Context, code string) veb.Result {
	if utf8_str_visible_length(code) > length_currency_code {
		return ctx.handle_error(errors.unprocessable_entity(error_field_too_long,
			'currency code must be exactly ${length_currency_code} UTF8 characters long'))
	}

	currency := app.with_rollback(fn [code] (mut tx firebird.ClientTransaction) !conduit.Currency {
		return conduit.currency_get(mut tx, code)
	}) or { return ctx.handle_error(err) }

	return ctx.handle_ok(CurrencyResponseEnvelope{
		currency: format_currency_response(currency)
	})
}
