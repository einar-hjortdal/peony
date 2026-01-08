module peony

import veb
import json

// lists sales channels
@['/admin/sales-channels'; get]
pub fn (mut app App) admin_sales_channels_get(mut ctx Context) veb.Result {
	p := extract_retrieve_sales_channels_params(ctx.query)
	if p.fetch.is_set && p.fetch.v == 0 {
		return handle_fetch_zero(mut ctx)
	}

	ids_bin := zero_array_id_string_to_array_id_bin(p.ids) or {
		return handle_error_400(mut ctx, error_id_invalid, err.msg())
	}

	ph := ListSalesChannelsParamsHygienised{
		ids:     p.ids
		ids_bin: ids_bin
		offset:  p.offset
		fetch:   p.fetch
		order:   p.order
	}

	return conduit_sales_channels_get(mut app, mut ctx, ph)
}

// retrieves a sales channel by id
@['/admin/sales-channels/:sales_channel_id'; get]
pub fn (mut app App) admin_sales_channels_id_get(mut ctx Context, sales_channel_id string) veb.Result {
	sales_channel_id_bin := id_string_to_bin(sales_channel_id) or {
		return handle_error_400(mut ctx, error_id_invalid, err.msg())
	}

	ph := ListSalesChannelsParamsHygienised{
		ids:     ZeroArrayString{
			is_set: true
		}
		ids_bin: [sales_channel_id_bin]
	}
	return conduit_sales_channels_get(mut app, mut ctx, ph)
}

// creates a sales channel
@['/admin/sales-channels'; post]
pub fn (mut app App) admin_sales_channels_post(mut ctx Context) veb.Result {
	p := json.decode(SalesChannelRequest, ctx.req.data) or {
		return handle_error_400(mut ctx, 'Could not decode SalesChannelRequest', err.msg())
	}

	if p.name == '' {
		return handle_error_400(mut ctx, 'name is required', 'name is empty')
	}

	return conduit_sales_channel_create(mut app, mut ctx, p)
}

// updates a sales channel
@['/admin/sales-channels/:sales_channel_id'; post]
pub fn (mut app App) admin_sales_channels_id_post(mut ctx Context, sales_channel_id string) veb.Result {
	sales_channel_id_bin := id_string_to_bin(sales_channel_id) or {
		return handle_error_400(mut ctx, error_id_invalid, 'sales_channel_id')
	}

	p := json.decode(SalesChannelUpdateRequest, ctx.req.data) or {
		return handle_error_400(mut ctx, 'Could not decode SalesChannelUpdateRequest',
			err.msg())
	}

	if name := p.name {
		if name == '' {
			return handle_error_400(mut ctx, 'name is required', 'name is empty')
		}
	}

	return conduit_sales_channel_update(mut app, mut ctx, sales_channel_id_bin, p)
}

// deletes a sales channel
@['/admin/sales-channels/:sales_channel_id'; delete]
pub fn (mut app App) admin_sales_channels_id_delete(mut ctx Context, sales_channel_id string) veb.Result {
	app.delete_sales_channel(sales_channel_id) or {
		return handle_error_500(mut ctx, 'Could not delete sales channel', err.msg())
	}

	return ctx.text('OK')
}

// updates products in the sales channel
// @['/admin/sales-channels/:sales_channel_id/products'; post]
// pub fn (mut app App) admin_sales_channels_id_products_post(mut ctx Context, sales_channel_id string) veb.Result {
// 	p := json.decode(ProductSalesChannelRequest, ctx.req.data) or {
// 		return handle_error_400(mut ctx, 'Could not decode ProductSalesChannelRequest',
// 			err.msg())
// 	}

// 	ph := hygienise_product_sales_channel_request(p) or {
// 		if err is InternalError {
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
		return handle_error_400(mut ctx, error_id_invalid, 'sales_channel_id')
	}

	stock_location_id_bin := id_string_to_bin(stock_location_id) or {
		return handle_error_400(mut ctx, error_id_invalid, 'stock_location_id')
	}

	return conduit_sales_channel_stock_location_add(mut app, mut ctx, sales_channel_id_bin,
		stock_location_id_bin)
}

// removes stock location from a channel
@['/admin/sales-channels/:sales_channel_id/stock-location/:stock_location_id'; delete]
pub fn (mut app App) admin_sales_channels_location_delete(mut ctx Context, sales_channel_id string, stock_location_id string) veb.Result {
	sales_channel_id_bin := id_string_to_bin(sales_channel_id) or {
		return handle_error_400(mut ctx, error_id_invalid, 'sales_channel_id')
	}

	stock_location_id_bin := id_string_to_bin(stock_location_id) or {
		return handle_error_400(mut ctx, error_id_invalid, 'stock_location_id')
	}

	return conduit_sales_channel_stock_location_delete(mut app, mut ctx, sales_channel_id_bin,
		stock_location_id_bin)
}
