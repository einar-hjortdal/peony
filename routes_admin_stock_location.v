module peony

import veb
import einar_hjortdal.firebird
import internal.conduit

// lists stock locations
@['/admin/stock-locations'; get]
pub fn (mut app App) stock_location_list(mut ctx Context) veb.Result {
	p := hygienise_stock_location_list_query_params(ctx.query) or { return ctx.handle_error(err) }
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
pub fn (mut app App) stock_location_get(mut ctx Context, stock_location_id string) veb.Result {
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

// creates a stock location
@['/admin/stock-locations'; post]
pub fn (mut app App) stock_location_create(mut ctx Context) veb.Result {
	stock_location_id := app.gen_id()
	p := hygienise_stock_location_create_request(ctx.req.data, stock_location_id) or {
		return ctx.handle_error(err)
	}

	stock_location := app.with_commit(fn [p] (mut tx firebird.ClientTransaction) !conduit.StockLocation {
		conduit.stock_location_create(mut tx, p)!
		return conduit.stock_location_get(mut tx, parsed_stock_location_id)
	}) or { return ctx.handle_error(err) }

	return ctx.handle_created(StockLocationResponseEnvelope{
		stock_location: format_stock_location_response(stock_location)
	})
}

// updates a stock location
@['/admin/stock-locations/:stock_location_id'; post]
pub fn (mut app App) stock_location_update(mut ctx Context, stock_location_id string) veb.Result {
	parsed_stock_location_id := id_from_string(stock_location_id) or {
		return ctx.handle_error(new_error_bad_request(error_id_invalid, 'stock_location_id'))
	}

	p := hygienise_stock_location_update_request(ctx.req.data, stock_location_id) or {
		return ctx.handle_error(err)
	}

	stock_location := app.with_commit(fn [p] (mut tx firebird.ClientTransaction) !conduit.StockLocation {
		conduit.stock_location_update(mut tx, p)!
		return conduit.stock_location_get(mut tx, parsed_stock_location_id)
	}) or { return ctx.handle_error(err) }

	return ctx.handle_created(StockLocationResponseEnvelope{
		stock_location: format_stock_location_response(stock_location)
	})
}

// deletes a stock location
@['/admin/stock-locations/:stock_location_id'; delete]
pub fn (mut app App) stock_location_delete(mut ctx Context, stock_location_id string) veb.Result {
	parsed_stock_location_id := id_from_string(stock_location_id) or {
		return ctx.handle_error(new_error_bad_request(error_id_invalid, 'stock_location_id'))
	}

	stock_location := app.with_commit(fn [parsed_stock_location_id] (mut tx firebird.ClientTransaction) !NilReturn {
		conduit.stock_location_delete(mut tx, parsed_stock_location_id)!
		return NilReturn{}
	}) or { return ctx.handle_error(err) }

	return ctx.handle_deleted()
}
