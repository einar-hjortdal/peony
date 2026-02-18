module peony

import veb

fn conduit_store_get(mut app App, mut ctx Context) veb.Result {
	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	mut store := model_store_retrieve(mut tx) or {
		perr := new_error_internal('Failed to retrieve store', err.msg())
		return ctx.handle_error(perr)
	}

	locales := model_store_locales_retrieve(mut tx) or {
		perr := new_error_internal('Failed to retrieve store locales', err.msg())
		return ctx.handle_error(perr)
	}

	tx.rollback() or {
		perr := new_error_internal(error_transaction_commit, err.msg())
		return ctx.handle_error(perr)
	}

	store.locales = locales

	r := StoreResponseEnvelope{
		store: format_store_response(store)
	}

	return ctx.json(r)
}

fn conduit_store_update(mut app App, mut ctx Context, store_id_bin []u8, ph StoreUpdateRequestHygienised) veb.Result {
	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	if ph.name != none || ph.default_locale_id != none || ph.default_region_id != none
		|| ph.default_stock_location_id != none || ph.default_sales_channel_id != none {
		model_store_update(mut tx, store_id_bin, ph) or {
			tx.rollback() or {}
			perr := new_error_internal('Could not update store data', err.msg())
			return ctx.handle_error(perr)
		}
	}

	if ph.locale_ids != none {
		model_store_locales_update(mut tx, store_id_bin, ph.locale_ids_bin) or {
			tx.rollback() or {}
			perr := new_error_internal('Could not update store locales', err.msg())
			return ctx.handle_error(perr)
		}
	}

	tx.commit() or {
		tx.rollback() or {}
		perr := new_error_internal(error_transaction_commit, err.msg())
		return ctx.handle_error(perr)
	}

	return success(mut ctx)
}
