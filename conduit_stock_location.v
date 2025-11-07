module peony

// import veb

// fn conduit_stock_location_list(mut app App, mut ctx Context) veb.Result {
// 	mut tx := app.start_transaction() or {
// 		return handle_error_500(mut ctx, error_transaction_start, err.msg())
// 	}

// 	stock_locations := model_stock_location_get(mut tx) or {
// 		tx.rollback() or {}
// 		return handle_error_500(mut ctx, 'Could not get stock_location', err.msg())
// 	}

// 	tx.rollback() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }

// 	external_stock_locations := []StockLocationResponse{}

// 	return success(mut ctx)
// }
