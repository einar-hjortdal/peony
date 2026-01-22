module peony

import veb

fn conduit_store_get(mut app App, mut ctx Context) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	mut store := model_store_retrieve(mut tx) or {
		return handle_error_500(mut ctx, 'Failed to retrieve store', err.msg())
	}

	locales := model_store_locales_retrieve(mut tx) or {
		return handle_error_500(mut ctx, 'Failed to retrieve store locales', err.msg())
	}

	tx.rollback() or { return handle_error_500(mut ctx, error_transaction_commit, err.msg()) }

	store.locales = locales

	r := StoreResponseEnvelope{
		store: format_store_response(store)
	}

	return ctx.json(r)
}

fn conduit_store_update(mut app App, mut ctx Context, store_id_bin []u8, ph StoreUpdateRequestHygienised) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	if ph.name != none || ph.default_locale_id != none || ph.default_region_id != none
		|| ph.default_stock_location_id != none || ph.default_sales_channel_id != none {
		model_store_update(mut tx, store_id_bin, ph) or {
			tx.rollback() or {}
			return handle_error_500(mut ctx, 'Could not update store data', err.msg())
		}
	}

	if ph.locale_ids != none {
		model_store_locales_update(mut tx, store_id_bin, ph.locale_ids_bin) or {
			tx.rollback() or {}
			return handle_error_500(mut ctx, 'Could not update store locales', err.msg())
		}
	}

	tx.commit() or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, error_transaction_commit, err.msg())
	}

	return success(mut ctx)
}
