module peony

import veb

@['/admin/stock-locations'; get]
pub fn (mut app App) admin_stock_location_list(mut ctx Context) veb.Result {
	// TODO params
	return conduit_stock_location_list(mut app, mut ctx)
}
