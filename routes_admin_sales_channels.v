module main

import net.http
import veb
import json

// lists sales channels
@['/admin/sales-channels'; get]
fn (mut app App) admin_sales_channels_get(mut ctx Context) veb.Result {
	p := extract_retrieve_sales_channels_params(ctx.query)

	sc := app.list_sales_channels(p) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Failed to retrieve sales channels data', err.msg()))
	}

	return ctx.json(sc)
}

// retrieves a sales channel by id
@['/admin/sales-channels/:id'; get]
fn (mut app App) admin_sales_channels_id_get(mut ctx Context, id string) veb.Result {
	sc := app.retrieve_sales_channel_by_id(id) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Could not retrieve sales channel data', err.msg()))
	}

	return ctx.json(sc)
}

// creates a sales channel
@['/admin/sales-channels'; post]
fn (mut app App) admin_sales_channels_post(mut ctx Context) veb.Result {
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
fn (mut app App) admin_sales_channels_id_post(mut ctx Context, id string) veb.Result {
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
fn (mut app App) admin_sales_channels_id_delete(mut ctx Context, id string) veb.Result {
	app.delete_sales_channel(id) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Could not delete sales channel', err.msg()))
	}

	return ctx.text('OK')
}

// add products to a sales channel
@['/admin/sales-channels/:id/products'; post]
fn (mut app App) admin_sales_channels_id_products_post(mut ctx Context, id string) veb.Result {
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
