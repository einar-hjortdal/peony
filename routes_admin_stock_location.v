module peony

import veb
import internal.conduit

// lists stock locations
@['/admin/stock-locations'; get]
pub fn (mut app App) admin_stock_location_list(mut ctx Context) veb.Result {
	// TODO params
	return conduit.stock_location_list(mut app, mut ctx, StockLocationRetrieveParams{})
}

// get a stock location by id
@['/admin/stock-locations/:stock_location_id'; get]
pub fn (mut app App) admin_stock_location_get(mut ctx Context, stock_location_id string) veb.Result {
	parsed_stock_location_id := id_from_string(stock_location_id) or {
		return ctx.handle_error(new_error_bad_request(error_id_invalid, 'stock_location_id'))
	}
	return conduit.stock_location_get(mut app, mut ctx, parsed_stock_location_id)
}
