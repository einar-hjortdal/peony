module peony

import veb
import json

// lists sales channels
@['/admin/sales-channels'; get]
pub fn (mut app App) admin_sales_channels_get(mut ctx Context) veb.Result {
	p := hygienise_sales_channels_list_query_params(ctx.query) or { return ctx.handle_error(err) }

	return conduit_sales_channels_get(mut app, mut ctx, p)
}

// retrieves a sales channel by id
@['/admin/sales-channels/:sales_channel_id'; get]
pub fn (mut app App) admin_sales_channels_id_get(mut ctx Context, sales_channel_id string) veb.Result {
	parsed_sales_channel_id := id_from_string(sales_channel_id) or {
		perr := new_error_bad_request(error_id_invalid, 'sales_channel_id')
		return ctx.handle_error(perr)
	}

	return conduit_sales_channels_get(mut app, mut ctx, SalesChannelRetrieveParams{
		ids:    [parsed_sales_channel_id]
		offset: offset_default
		fetch:  1
		order:  order_direction_default
	})
}

// creates a sales channel
@['/admin/sales-channels'; post]
pub fn (mut app App) admin_sales_channels_post(mut ctx Context) veb.Result {
	p := json.decode(SalesChannelRequest, ctx.req.data) or {
		perr := new_error_bad_request('Could not decode SalesChannelRequest', err.msg())
		return ctx.handle_error(perr)
	}

	if p.name == '' {
		perr := new_error_bad_request('name is required', 'name is empty')
		return ctx.handle_error(perr)
	}

	return conduit_sales_channel_create(mut app, mut ctx, p)
}

// updates a sales channel
@['/admin/sales-channels/:sales_channel_id'; post]
pub fn (mut app App) admin_sales_channels_id_post(mut ctx Context, sales_channel_id string) veb.Result {
	sales_channel_id_bin := id_string_to_bin(sales_channel_id) or {
		perr := new_error_bad_request(error_id_invalid, 'sales_channel_id')
		return ctx.handle_error(perr)
	}

	p := json.decode(SalesChannelUpdateRequest, ctx.req.data) or {
		perr := new_error_bad_request('Could not decode SalesChannelUpdateRequest', err.msg())
		return ctx.handle_error(perr)
	}

	if name := p.name {
		if name == '' {
			perr := new_error_bad_request('name is required', 'name is empty')
			return ctx.handle_error(perr)
		}
	}

	return conduit_sales_channel_update(mut app, mut ctx, sales_channel_id_bin, p)
}

// deletes a sales channel
@['/admin/sales-channels/:sales_channel_id'; delete]
pub fn (mut app App) admin_sales_channels_id_delete(mut ctx Context, sales_channel_id string) veb.Result {
	app.delete_sales_channel(sales_channel_id) or {
		perr := new_error_internal('Could not delete sales channel', err.msg())
		return ctx.handle_error(perr)
	}

	return ctx.text('OK') // TODO
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
	sales_channel_id_bin := id_string_to_bin(sales_channel_id) or {
		perr := new_error_bad_request(error_id_invalid, 'sales_channel_id')
		return ctx.handle_error(perr)
	}

	stock_location_id_bin := id_string_to_bin(stock_location_id) or {
		perr := new_error_bad_request(error_id_invalid, 'stock_location_id')
		return ctx.handle_error(perr)
	}

	return conduit_sales_channel_stock_location_add(mut app, mut ctx, sales_channel_id_bin,
		stock_location_id_bin)
}

// removes stock location from a channel
@['/admin/sales-channels/:sales_channel_id/stock-location/:stock_location_id'; delete]
pub fn (mut app App) admin_sales_channels_location_delete(mut ctx Context, sales_channel_id string, stock_location_id string) veb.Result {
	sales_channel_id_bin := id_string_to_bin(sales_channel_id) or {
		perr := new_error_bad_request(error_id_invalid, 'sales_channel_id')
		return ctx.handle_error(perr)
	}

	stock_location_id_bin := id_string_to_bin(stock_location_id) or {
		perr := new_error_bad_request(error_id_invalid, 'stock_location_id')
		return ctx.handle_error(perr)
	}

	return conduit_sales_channel_stock_location_delete(mut app, mut ctx, sales_channel_id_bin,
		stock_location_id_bin)
}

