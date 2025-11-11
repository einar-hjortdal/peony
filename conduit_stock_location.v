module peony

import veb

fn conduit_stock_location_list(mut app App, mut ctx Context) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	stock_locations := model_stock_location_get(mut tx) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not get stock_location', err.msg())
	}

	tx.rollback() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }

	mut external_stock_locations := []StockLocationResponse{len: stock_locations.len}
	for i := 0; i < stock_locations.len; i++ {
		external_stock_locations[i] = format_stock_location_response(stock_locations[i])
	}

	return ctx.json(StockLocationResponseListEnvelope{
		stock_locations: external_stock_locations
		// TODO params
	})
}
