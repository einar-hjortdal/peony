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
		ids:         p.ids
		ids_bin:     ids_bin
		name:        p.name
		description: p.description
		offset:      p.offset
		fetch:       p.fetch
		order:       p.order
	}

	return conduit_sales_channels_get(mut app, mut ctx, ph)
}

// retrieves a sales channel by id
@['/admin/sales-channels/:id'; get]
pub fn (mut app App) admin_sales_channels_id_get(mut ctx Context, id string) veb.Result {
	id_bin := id_string_to_bin(id) or {
		return handle_error_400(mut ctx, error_id_invalid, err.msg())
	}

	ph := ListSalesChannelsParamsHygienised{
		ids:     ZeroArrayString{
			is_set: true
		}
		ids_bin: [id_bin]
	}
	return conduit_sales_channels_get(mut app, mut ctx, ph)
}

// creates a sales channel
@['/admin/sales-channels'; post]
pub fn (mut app App) admin_sales_channels_post(mut ctx Context) veb.Result {
	data := json.decode(NewSalesChannelData, ctx.req.data) or {
		return handle_error_400(mut ctx, 'Could not decode NewSalesChannelData', err.msg())
	}

	id, _ := app.create_sales_channel(data) or {
		return handle_error_500(mut ctx, 'Could not create sales channel', err.msg())
	}

	return app.admin_sales_channels_id_get(mut ctx, id)
}

// updates a sales channel
@['/admin/sales-channels/:id'; post]
pub fn (mut app App) admin_sales_channels_id_post(mut ctx Context, id string) veb.Result {
	p := NewSalesChannelData{
		name:        ctx.query['name']
		description: ctx.query['description']
		is_disabled: parse_bool(ctx.query['is_disabled'])
	}

	app.update_sales_channel(id, p) or {
		return handle_error_500(mut ctx, 'Could not update sales channel data', err.msg())
	}

	return app.admin_sales_channels_id_get(mut ctx, id)
}

// deletes a sales channel
@['/admin/sales-channels/:id'; delete]
pub fn (mut app App) admin_sales_channels_id_delete(mut ctx Context, id string) veb.Result {
	app.delete_sales_channel(id) or {
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

// associate stock location to a channel
// remove stock location from a channel
