module peony

import net.http
import veb

fn conduit_store_get(mut app App, mut ctx Context) veb.Result {
	internal_store := app.store_retrieve() or {
		return handle_error_500(mut ctx, 'Failed to retrieve store data', err.msg())
	}

	r := StoreResponseEnvelope{
		store: format_store_response(internal_store)
	}

	return ctx.json(r)
}

fn conduit_store_update(mut app App, mut ctx Context, id_bin []u8, ph StoreRequestHygienised) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	if ph.name != none || ph.default_locale_id != none || ph.default_currency_code != none
		|| ph.default_stock_location_id != none || ph.default_sales_channel_id != none {
		app.do_store_update(mut tx, id_bin, ph) or {
			tx.rollback() or {}
			return handle_error_500(mut ctx, 'Could not update store data', err.msg())
		}
	}

	if ph.locale_ids != none {
		app.do_update_store_locales(mut tx, id_bin, ph.locale_ids_bin) or {
			tx.rollback() or {}
			return handle_error_500(mut ctx, 'Could not update store locales', err.msg())
		}
	}

	if currency_codes := ph.currency_codes {
		app.do_update_store_currencies(mut tx, id_bin, currency_codes) or {
			tx.rollback() or {}
			return handle_error_500(mut ctx, 'Could not update store currencies', err.msg())
		}
	}

	tx.commit() or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, error_transaction_commit, err.msg())
	}

	return ctx.json(new_peony_success())
}
