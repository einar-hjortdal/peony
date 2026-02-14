module peony

import veb

fn conduit_locale_list(mut app App, mut ctx Context, ph LocaleRetrieveParamsHygienised) veb.Result {
	mut tx := app.start_transaction() or {
		perr := new_error_internal(error_transaction_start, err.msg())
		return ctx.handle_peony_error(perr)
	}

	count := model_locale_retrieve_count(mut tx, ph) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not retrieve locale count', err.msg())
		return ctx.handle_peony_error(perr)
	}

	if count == 0 {
		tx.rollback() or {
			perr := new_error_internal(error_transaction_rollback, err.msg())
			return ctx.handle_peony_error(perr)
		}
		return ctx.json(LocaleResponseListEnvelope{
			locales: []LocaleResponse{}
			count:   count
			offset:  get_offset_amount(ph.offset)
			fetch:   get_fetch_amount(ph.fetch)
		})
	}

	locales := model_locale_retrieve(mut tx, ph) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not retrieve locale', err.msg())
		return ctx.handle_peony_error(perr)
	}

	tx.rollback() or {
		perr := new_error_internal(error_transaction_rollback, err.msg())
		return ctx.handle_peony_error(perr)
	}

	mut external_locales := []LocaleResponse{len: locales.len}
	for i := 0; i < locales.len; i++ {
		external_locales[i] = format_locale_response(locales[i])
	}

	return ctx.json(LocaleResponseListEnvelope{
		locales: external_locales
		count:   count
		offset:  get_offset_amount(ph.offset)
		fetch:   get_fetch_amount(ph.fetch)
	})
}

fn conduit_locale_get(mut app App, mut ctx Context, ph LocaleRetrieveParamsHygienised) veb.Result {
	mut tx := app.start_transaction() or {
		perr := new_error_internal(error_transaction_start, err.msg())
		return ctx.handle_peony_error(perr)
	}

	locales := model_locale_retrieve(mut tx, ph) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not retrieve locale', err.msg())
		return ctx.handle_peony_error(perr)
	}

	tx.rollback() or {} // ignore error

	if locales.len == 0 {
		perr := new_error_not_found('No locale exists with the given id', 'locales.len == 0')
		return ctx.handle_peony_error(perr)
	}

	return ctx.json(LocaleResponseEnvelope{
		locale: format_locale_response(locales[0])
	})
}
