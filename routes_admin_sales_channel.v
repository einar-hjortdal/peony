module peony

import veb
import einar_hjortdal.firebird
import internal.common
import internal.conduit
import internal.errors

// lists sales channels
@['/admin/sales-channels'; get]
pub fn (mut app App) admin_sales_channels_get(mut ctx Context) veb.Result {
	p := hygienise_sales_channels_list_query_params(ctx.query) or { return ctx.handle_error(err) }
	data := app.with_rollback(fn [p] (mut tx firebird.ClientTransaction) !conduit.List[conduit.SalesChannel] {
		return conduit.sales_channel_list(mut tx, p)
	}) or { return ctx.handle_error(err) }

	return ctx.handle_ok(SalesChannelResponseListEnvelope{
		sales_channels: format_sales_channel_response_list(data.items)
	})
}

// retrieves a sales channel by id
@['/admin/sales-channels/:sales_channel_id'; get]
pub fn (mut app App) admin_sales_channels_id_get(mut ctx Context, sales_channel_id string) veb.Result {
	parsed_sales_channel_id := common.id_from_string(sales_channel_id) or {
		return ctx.handle_error(errors.bad_request(errors.id_invalid, 'sales_channel_id'))
	}

	sales_channel := app.with_rollback(fn [parsed_sales_channel_id] (mut tx firebird.ClientTransaction) !conduit.SalesChannel {
		return conduit.sales_channel_get(mut tx, parsed_sales_channel_id)!
	}) or { return ctx.handle_error(err) }

	return ctx.handle_ok(SalesChannelResponseEnvelope{
		sales_channel: format_sales_channel_response(sales_channel)
	})
}

// creates a sales channel
@['/admin/sales-channels'; post]
pub fn (mut app App) admin_sales_channels_post(mut ctx Context) veb.Result {
	sales_channel_id := app.gen_id()
	p := hygienise_sales_channel_create_request(ctx.req.data, sales_channel_id) or {
		return ctx.handle_error(err)
	}

	sales_channel := app.with_commit(fn [p, sales_channel_id] (mut tx firebird.ClientTransaction) !conduit.SalesChannel {
		conduit.sales_channel_create(mut tx, p)!
		return conduit.sales_channel_get(mut tx, sales_channel_id)
	}) or { return ctx.handle_error(err) }

	return ctx.handle_created(SalesChannelResponseEnvelope{
		sales_channel: format_sales_channel_response(sales_channel)
	})
}

// updates a sales channel
@['/admin/sales-channels/:sales_channel_id'; post]
pub fn (mut app App) admin_sales_channels_id_post(mut ctx Context, sales_channel_id string) veb.Result {
	parsed_sales_channel_id := common.id_from_string(sales_channel_id) or {
		return ctx.handle_error(errors.unprocessable_entity(errors.id_invalid, 'sales_channel_id'))
	}

	p := hygienise_sales_channel_update_request(ctx.req.data, parsed_sales_channel_id) or {
		return ctx.handle_error(err)
	}

	sales_channel := app.with_commit(fn [p, parsed_sales_channel_id] (mut tx firebird.ClientTransaction) !conduit.SalesChannel {
		conduit.sales_channel_update(mut tx, p)!
		return conduit.sales_channel_get(mut tx, parsed_sales_channel_id)
	}) or { return ctx.handle_error(err) }

	return ctx.handle_ok(SalesChannelResponseEnvelope{
		sales_channel: format_sales_channel_response(sales_channel)
	})
}

// deletes a sales channel
@['/admin/sales-channels/:sales_channel_id'; delete]
pub fn (mut app App) admin_sales_channels_id_delete(mut ctx Context, sales_channel_id string) veb.Result {
	parsed_sales_channel_id := common.id_from_string(sales_channel_id) or {
		return ctx.handle_error(errors.unprocessable_entity(errors.id_invalid, 'sales_channel_id'))
	}

	app.with_commit(fn [parsed_sales_channel_id] (mut tx firebird.ClientTransaction) !common.Empty {
		conduit.sales_channel_delete(mut tx, parsed_sales_channel_id)!
		return common.Empty{}
	}) or { return ctx.handle_error(err) }

	return ctx.handle_deleted()
}

// updates products in the sales channel
// @['/admin/sales-channels/:sales_channel_id/products'; post]
// pub fn (mut app App) admin_sales_channels_id_products_post(mut ctx Context, sales_channel_id string) veb.Result {
// 	p := json.decode(ProductSalesChannelRequest, ctx.req.data) or {
// 		return handle_error_400(mut ctx, 'Could not decode ProductSalesChannelRequest',
// 			err.msg())
// 	}

// 	ph := hygienise_product_sales_channel_request(p) or {
// 		if err is PeonyError {
// 			return handle_error_400(mut ctx, err.message, err.details)
// 		} else {
// 			return handle_error_400(mut ctx, 'Unhandled error at hygienise_product_sales_channel_request',
// 				err.msg())
// 		}
// 	}

// 	return conduit_product_sales_channel_update(sales_channel_id_bin, ph)
// }

// associates stock location to a channel
@['/admin/sales-channels/:sales_channel_id/stock-location/:stock_location_id'; post]
pub fn (mut app App) admin_sales_channels_location_post(mut ctx Context, sales_channel_id string, stock_location_id string) veb.Result {
	parsed_sales_channel_id := common.id_from_string(sales_channel_id) or {
		return ctx.handle_error(errors.bad_request(errors.id_invalid, 'sales_channel_id'))
	}

	parsed_stock_location_id := common.id_from_string(stock_location_id) or {
		return ctx.handle_error(errors.bad_request(errors.id_invalid, 'stock_location_id'))
	}

	sales_channel := app.with_commit(fn [parsed_sales_channel_id, parsed_stock_location_id] (mut tx firebird.ClientTransaction) !conduit.SalesChannel {
		conduit.sales_channel_stock_location_add(mut tx, parsed_sales_channel_id,
			parsed_stock_location_id)!
		return conduit.sales_channel_get(mut tx, parsed_sales_channel_id)
	}) or { return ctx.handle_error(err) }

	return ctx.handle_ok(SalesChannelResponseEnvelope{
		sales_channel: format_sales_channel_response(sales_channel)
	})
}

// removes stock location from a channel
@['/admin/sales-channels/:sales_channel_id/stock-location/:stock_location_id'; delete]
pub fn (mut app App) admin_sales_channels_location_delete(mut ctx Context, sales_channel_id string, stock_location_id string) veb.Result {
	parsed_sales_channel_id := common.id_from_string(sales_channel_id) or {
		return ctx.handle_error(errors.unprocessable_entity(errors.id_invalid, 'sales_channel_id'))
	}

	parsed_stock_location_id := common.id_from_string(stock_location_id) or {
		return ctx.handle_error(errors.unprocessable_entity(errors.id_invalid, 'stock_location_id'))
	}

	sales_channel := app.with_commit(fn [parsed_sales_channel_id, parsed_stock_location_id] (mut tx firebird.ClientTransaction) !conduit.SalesChannel {
		conduit.sales_channel_stock_location_delete(mut tx, parsed_sales_channel_id,
			parsed_stock_location_id)!
		return conduit.sales_channel_get(mut tx, parsed_sales_channel_id)
	}) or { return ctx.handle_error(err) }

	return ctx.handle_ok(SalesChannelResponseEnvelope{
		sales_channel: format_sales_channel_response(sales_channel)
	})
}
