module main

import net.http
import veb
import json

// deletes a product option
@['/admin/options/:id'; delete]
fn (mut app App) admin_products_id_options_delete(mut ctx Context, id string) veb.Result {
	id_bin := id_string_to_bin(id) or {
		ctx.res.set_status(http.Status.bad_request)
		return ctx.json(new_peony_error('Invalid id', err.msg()))
	}

	app.delete_product_option(id_bin) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Failed to delete product option', err.msg()))
	}
	return ctx.json(new_peony_success())
}

// updates a product option
@['/admin/options/:id'; post]
fn (mut app App) admin_products_id_options_option_id_post(mut ctx Context, id string) veb.Result {
	id_bin := id_string_to_bin(id) or {
		ctx.res.set_status(http.Status.bad_request)
		return ctx.json(new_peony_error('Invalid id', err.msg()))
	}

	data := json.decode(ProductOptionData, ctx.req.data) or {
		ctx.res.set_status(http.Status.bad_request)
		return ctx.json(new_peony_error('Could not decode body', err.msg()))
	}

	app.update_product_option(id_bin, data) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Failed to create product option', err.msg()))
	}

	return ctx.json(new_peony_success())
}
