module peony

import veb
import einar_hjortdal.firebird
import internal.conduit

// lists stock locations
@['/admin/stock-locations'; get]
pub fn (mut app App) admin_stock_location_list(mut ctx Context) veb.Result {
	p := hygienise_stock_location_query_params(ctx.query) or { return ctx.handle_error(err) }
	data := app.with_rollback(fn [p] (mut tx firebird.ClientTransaction) ![]ListReturn {
		count := conduit.region_list_count(mut tx, p)!
		if count == 0 {
			return ListReturn{}
		}

		stock_locations := conduit.stock_location_list(mut tx, p)
		regions := conduit.region_list(mut tx, p)!
		return ListReturn{
			count: count
			items: stock_locations
		}
	}) or { return ctx.handle_error(err) }

	if data.count == 0 {
		return ctx.json(StockLocationResponseListEnvelope{
			offset: p.offset
			fetch:  p.fetch
		})
	}

	return ctx.handle_ok(StockLocationResponseListEnvelope{
		stock_location: format_stock_location_response_list(data.items)
		count:          count
		offset:         p.offset
		fetch:          p.fetch
	})
}

// get a stock location by id
@['/admin/stock-locations/:stock_location_id'; get]
pub fn (mut app App) admin_stock_location_get(mut ctx Context, stock_location_id string) veb.Result {
	parsed_stock_location_id := id_from_string(stock_location_id) or {
		return ctx.handle_error(new_error_bad_request(error_id_invalid, 'stock_location_id'))
	}

	stock_location := app.with_rollback(fn [parsed_stock_location_id] (mut tx firebird.ClientTransaction) !conduit.StockLocation {
		return conduit.stock_location_get(mut tx, parsed_stock_location_id)
	}) or { return ctx.handle_error(err) }

	return ctx.handle_ok(StockLocationResponseEnvelope{
		stock_location: format_stock_location_response(stock_location)
	})
}
