module peony

import veb
import net.http

fn conduit_locale_get(mut app App, mut ctx Context, p RetrieveLocalesParams) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	internal_locales, count := model_retrieve_locales(mut tx, p) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve locales', err.msg())
	}

	tx.rollback() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }

	mut external_locales := []LocaleResponse{len: internal_locales.len}
	for i := 0; i < internal_locales.len; i++ {
		external_locales[i] = format_locale_response(internal_locales[i])
	}

	r := LocaleResponseEnvelope{
		locales: external_locales
		count:   count
		offset:  get_offset_amount(p.offset)
		fetch:   get_fetch_amount(p.fetch)
	}
	return ctx.json(r)
}
