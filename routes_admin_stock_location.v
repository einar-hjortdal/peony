module peony

import veb

// lists stock locations
@['/admin/stock-locations'; get]
pub fn (mut app App) admin_stock_location_list(mut ctx Context) veb.Result {
	// TODO params
	p := StockLocationRetrieveParams{}
	return conduit_stock_location_list(mut app, mut ctx, p)
}

// get a stock location by id
@['/admin/stock-locations/:stock_location_id}'; get]
pub fn (mut app App) admin_stock_location_get(mut ctx Context, stock_location_id string) veb.Result {
	stock_location_id_bin := id_string_to_bin(stock_location_id) or {
		perr := new_error_bad_request(error_id_invalid, 'stock_location_id')
		return ctx.handle_error(perr)
	}
	return conduit_stock_location_get(mut app, mut ctx, stock_location_id_bin)
}
