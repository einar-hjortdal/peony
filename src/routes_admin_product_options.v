module main

import net.http
import veb
import json

// deletes a product option
@['/admin/options/:id'; delete]
fn (mut app App) admin_products_id_options_delete(mut ctx Context, id string) veb.Result {
	app.delete_product_option(id) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Failed to delete product option', err.msg()))
	}
	return ctx.text('ok') // TODO better response
}

// updates a product option
@['/admin/options/:id'; post]
fn (mut app App) admin_products_id_options_option_id_post(mut ctx Context, id string) veb.Result {
	data := json.decode(UpdateProductOptionData, ctx.req.data) or {
		ctx.res.set_status(http.Status.bad_request)
		return ctx.json(new_peony_error('Could not decode body', err.msg()))
	}

	_ := app.update_product_option(id, data) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Failed to create product option', err.msg()))
	}

	return ctx.text('ok') // TODO return option?
}

// adds or updates a product option translation
@['/admin/options/:id/translations'; post]
fn (mut app App) admin_products_id_options_option_id_translations_post(mut ctx Context, id string) veb.Result {
	data := json.decode(ProductOptionTranslationData, ctx.req.data) or {
		ctx.res.set_status(http.Status.bad_request)
		return ctx.json(new_peony_error('Could not decode body', err.msg()))
	}

	app.update_product_option_translation(id, data) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Failed to add or update product option translation',
			err.msg()))
	}

	return ctx.text('ok') // TODO return option?
}

// deletes a product option translation
fn (mut app App) admin_products_id_options_option_id_translations_delete(mut ctx Context, id string) veb.Result {
	data := json.decode(struct {
		locale_code string
	}, ctx.req.data) or {
		ctx.res.set_status(http.Status.bad_request)
		return ctx.json(new_peony_error('Could not decode body', err.msg()))
	}

	app.delete_product_option_translation(id, data.locale_code) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Failed to delete product option', err.msg()))
	}

	return ctx.text('ok') // TODO return option?
}
