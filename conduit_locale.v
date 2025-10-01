module peony

import veb

fn conduit_locale_get(mut app App, mut ctx Context, ph LocaleRetrieveParamsHygienised) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	count := model_locale_retrieve_count(mut tx, ph) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve locale count', err.msg())
	}

	if count == 0 {
		return ctx.json(ListLocaleResponseEnvelope{
			locales: []LocaleResponse{}
			count:   count
			offset:  get_offset_amount(ph.offset)
			fetch:   ph.fetch.v
		})
	}

	locales := model_locale_retrieve(mut tx, ph) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve locale', err.msg())
	}

	tx.rollback() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }

	mut external_locales := []LocaleResponse{len: locales.len}
	for i := 0; i < locales.len; i++ {
		external_locales[i] = format_locale_response(locales[i])
	}

	return ctx.json(ListLocaleResponseEnvelope{
		locales: external_locales
		count:   count
		offset:  get_offset_amount(ph.offset)
		fetch:   ph.fetch.v
	})
}

fn conduit_locale_get_by_id(mut app App, mut ctx Context, ph LocaleRetrieveParamsHygienised) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	locales := model_locale_retrieve(mut tx, ph) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve locale', err.msg())
	}

	tx.rollback() or {} // ignore error

	if locales.len == 0 {
		return handle_error_404(mut ctx, 'Not found', 'No locale exists with the given id')
	}

	return ctx.json(LocaleResponseEnvelope{
		locale: format_locale_response(locales[0])
	})
}
