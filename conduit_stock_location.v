module peony

import veb

fn conduit_stock_location_list(mut app App, mut ctx Context, p StockLocationRetrieveParams) veb.Result {
	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	stock_locations := model_stock_location_retrieve(mut tx, p) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not get stock_location', err.msg())
		return ctx.handle_error(perr)
	}

	tx.rollback() or {
		perr := new_error_internal(error_transaction_rollback, err.msg())
		return ctx.handle_error(perr)
	}

	mut external_stock_locations := []StockLocationResponse{len: stock_locations.len}
	for i := 0; i < stock_locations.len; i++ {
		external_stock_locations[i] = format_stock_location_response(stock_locations[i])
	}

	return ctx.json(StockLocationResponseListEnvelope{
		stock_locations: external_stock_locations
		// TODO params
	})
}

fn conduit_stock_location_get(mut app App, mut ctx Context, stock_location_id_bin []u8) veb.Result {
	p := StockLocationRetrieveParams{
		filter_by_id: true
		ids_bin:      [stock_location_id_bin]
	}

	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	stock_locations := model_stock_location_retrieve(mut tx, p) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not get stock_location', err.msg())
		return ctx.handle_error(perr)
	}

	tx.rollback() or {
		perr := new_error_internal(error_transaction_rollback, err.msg())
		return ctx.handle_error(perr)
	}

	stock_location := stock_locations[0]

	return ctx.json(StockLocationResponseEnvelope{
		stock_location: format_stock_location_response(stock_location)
		// TODO params
	})
}
