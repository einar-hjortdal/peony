module peony

import net.http
import veb
import json

// lists sales channels
@['/admin/sales-channels'; get]
pub fn (mut app App) admin_sales_channels_get(mut ctx Context) veb.Result {
	p := extract_retrieve_sales_channels_params(ctx.query)

	ids_bin := zero_array_id_string_to_array_id_bin(p.ids) or {
		return handle_error(mut ctx, http.Status.bad_request, error_id_invalid, err.msg())
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
		return handle_error(mut ctx, http.Status.bad_request, error_id_invalid, err.msg())
	}
	ids_bin := [id_bin]
	return conduit_sales_channels_get_by_id(mut app, mut ctx, ids_bin)
}

// creates a sales channel
@['/admin/sales-channels'; post]
pub fn (mut app App) admin_sales_channels_post(mut ctx Context) veb.Result {
	data := json.decode(NewSalesChannelData, ctx.req.data) or {
		ctx.res.set_status(http.Status.bad_request)
		return ctx.json(new_peony_error('Could not decode NewSalesChannelData', err.msg()))
	}

	id, _ := app.create_sales_channel(data) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Could not create sales channel', err.msg()))
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
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Could not update sales channel data', err.msg()))
	}

	return app.admin_sales_channels_id_get(mut ctx, id)
}

// deletes a sales channel
@['/admin/sales-channels/:id'; delete]
pub fn (mut app App) admin_sales_channels_id_delete(mut ctx Context, id string) veb.Result {
	app.delete_sales_channel(id) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Could not delete sales channel', err.msg()))
	}

	return ctx.text('OK')
}

// add products to a sales channel
@['/admin/sales-channels/:id/products'; post]
pub fn (mut app App) admin_sales_channels_id_products_post(mut ctx Context, id string) veb.Result {
	data := json.decode(struct {
		product_ids []string
	}, ctx.req.data) or {
		ctx.res.set_status(http.Status.bad_request)
		return ctx.json(new_peony_error('Could not decode request body', err.msg()))
	}
	app.add_products_to_sales_channel(id, data.product_ids) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Could not associate products to sales channel',
			err.msg()))
	}
	return app.admin_sales_channels_id_get(mut ctx, id)
}

// remove products from a sales channel
// associate stock location to a channel
// remove stock location from a channel
