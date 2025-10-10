module peony

import json
import veb

// lists products
@['/admin/products'; get]
pub fn (mut app App) admin_products_get(mut ctx Context) veb.Result {
	ph := hygienise_retrieve_product_params(ctx.query) or {
		if err is InternalError {
			return handle_error_400(mut ctx, err.message, err.details)
		}
		return handle_error_500(mut ctx, 'Unhandled error at hygienise_product_request',
			err.msg())
	}

	if ph.fetch.is_set && ph.fetch.v == 0 {
		return handle_fetch_zero(mut ctx)
	}

	return conduit_products_get(mut app, mut ctx, ph)
}

// create a product
@['/admin/products'; post]
pub fn (mut app App) admin_products_post(mut ctx Context) veb.Result {
	p := json.decode(ProductRequest, ctx.req.data) or {
		return handle_error_400(mut ctx, 'Could not decode ProductRequest', err.msg())
	}

	ph := hygienise_product_request(p) or {
		if err is InternalError {
			return handle_error_400(mut ctx, err.message, err.details)
		}
		return handle_error_500(mut ctx, 'Unhandled error at hygienise_product_request',
			err.msg())
	}

	if translations := ph.translations {
		if translations.len == 0 {
			return handle_error_400(mut ctx, 'A product title is required', 'translations')
		}
	} else {
		return handle_error_400(mut ctx, 'A product title is required', 'translations')
	}

	return conduit_product_create(mut app, mut ctx, ph)
}

// retrieves a list of tags and the amount of times each tag is being used by products
@['/admin/products/tag-usage'; get]
pub fn (app &App) admin_products_tag_usage_get(mut ctx Context) veb.Result {
	return ctx.json('TODO')
}

// get a product
@['/admin/products/:id'; get]
pub fn (mut app App) admin_products_id_get(mut ctx Context, id string) veb.Result {
	id_bin := id_string_to_bin(id) or {
		return handle_error_400(mut ctx, error_id_invalid, err.msg())
	}

	ph := RetrieveProductParamsHygienised{
		ids:     ZeroArrayString{
			is_set: true
		}
		ids_bin: [id_bin]
	}

	return conduit_products_get_by_id(mut app, mut ctx, ph)
}

// updates a product
@['/admin/products/:product_id'; post]
pub fn (mut app App) admin_products_id_post(mut ctx Context, product_id string) veb.Result {
	product_id_bin := id_string_to_bin(product_id) or {
		return handle_error_400(mut ctx, error_id_invalid, 'product_id')
	}

	p := json.decode(ProductRequest, ctx.req.data) or {
		return handle_error_400(mut ctx, 'Could not decode ProductRequest', err.msg())
	}

	ph := hygienise_product_request(p) or {
		if err is InternalError {
			return handle_error_400(mut ctx, err.message, err.details)
		}
		return handle_error_400(mut ctx, 'Unhandled error at hygienise_product_request',
			err.msg())
	}

	if translations := ph.translations {
		if translations.len == 0 {
			return handle_error_400(mut ctx, 'A product name is required', 'translations')
		}
	}

	return conduit_products_update(mut app, mut ctx, product_id_bin, ph)
}

// deletes a product
@['/admin/products/:product_id'; delete]
pub fn (mut app App) admin_products_id_delete(mut ctx Context, product_id string) veb.Result {
	product_id_bin := id_string_to_bin(product_id) or {
		return handle_error_400(mut ctx, error_id_invalid, 'product_id')
	}
	return conduit_product_delete(mut app, mut ctx, product_id_bin)
}

// creates a product variant
@['/admin/products/:product_id/variants/'; post]
pub fn (mut app App) admin_products_id_variants_post(mut ctx Context, product_id string) veb.Result {
	product_id_bin := id_string_to_bin(product_id) or {
		return handle_error_400(mut ctx, error_id_invalid, err.msg())
	}

	p := json.decode(ProductVariantRequest, ctx.req.data) or {
		return handle_error_400(mut ctx, 'Could not decode VariantRequest ', err.msg())
	}

	ph := hygienise_product_variant_request(p) or {
		if err is InternalError {
			return handle_error_400(mut ctx, err.message, err.details)
		}
		return handle_error_unhandled(mut ctx, err.msg(), 'hygienise_product_variant_request')
	}

	if ph.title == none {
		return handle_error_400(mut ctx, 'title is required', 'title not provided')
	}

	if title := ph.title {
		if title == '' {
			return handle_error_400(mut ctx, 'title is required', 'title not provided')
		}
	}

	if option_value_ids := ph.option_value_ids {
		mut tx := app.start_transaction() or {
			return handle_error_500(mut ctx, error_transaction_start, err.msg())
		}

		existing_options := model_product_options_retrieve_by_product_ids(mut tx, [
			product_id_bin,
		]) or {
			tx.rollback() or {}
			return handle_error_500(mut ctx, 'Could not retrieve product options', err.msg())
		}

		tx.rollback() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }

		// verify:
		// they exist in product_option_value table
		// there is exactly one for each product_option
		// there isn't one variant with the same ones already
	}

	return conduit_product_variant_create(mut app, mut ctx, product_id_bin, ph)
}

// updates a product variant
@['/admin/products/:product_id/variants/:variant_id'; post]
pub fn (mut app App) admin_variants_id_post(mut ctx Context, product_id string, variant_id string) veb.Result {
	product_id_bin := id_string_to_bin(product_id) or {
		return handle_error_400(mut ctx, error_id_invalid, 'product_id')
	}

	variant_id_bin := id_string_to_bin(variant_id) or {
		return handle_error_400(mut ctx, error_id_invalid, 'variant_id')
	}

	p := json.decode(ProductVariantRequest, ctx.req.data) or {
		return handle_error_400(mut ctx, 'Could not decode VariantRequest', err.msg())
	}

	ph := hygienise_product_variant_request(p) or {
		if err is InternalError {
			return handle_error_400(mut ctx, err.message, err.details)
		}
		return handle_error_unhandled(mut ctx, err.msg(), 'hygienise_product_variant_request')
	}

	return conduit_product_variant_update(mut app, mut ctx, product_id_bin, variant_id_bin,
		ph)
}

// deletes a product variant
@['/admin/products/:product_id/variants/:variant_id'; delete]
pub fn (mut app App) admin_variants_id_delete(mut ctx Context, product_id string, variant_id string) veb.Result {
	product_id_bin := id_string_to_bin(product_id) or {
		return handle_error_400(mut ctx, error_id_invalid, 'product_id')
	}

	variant_id_bin := id_string_to_bin(variant_id) or {
		return handle_error_400(mut ctx, error_id_invalid, 'variant_id')
	}

	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	ph := RetrieveProductVariantParamsHygienised{
		product_ids:     ZeroArrayString{
			is_set: true
		}
		product_ids_bin: [product_id_bin]
	}

	count := model_product_variants_retrieve_count(mut tx, ph) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve variants', err.msg())
	}

	if count == 0 {
		return handle_error_500(mut ctx, 'product_variant does not exist', 'count == 0')
	}

	product_variants := model_product_variants_retrieve(mut tx, ph) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve product_variant', err.msg())
	}

	tx.rollback() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }

	for i := 0; i < product_variants.len; i++ {
		if product_variants[i].id_bin != variant_id_bin {
			continue
		}

		if product_variants.len == 1 {
			return handle_error_400(mut ctx, 'Cannot delete product_variant', 'A product must have at least 1 variant')
		}

		inventory_item_id_bin := product_variants[i].inventory_item.id_bin
		return conduit_product_variant_delete(mut app, mut ctx, variant_id_bin, inventory_item_id_bin)
	}

	return handle_error_404(mut ctx, 'product_variant does not exist', 'no product_variant with provided id')
}

// creates a product option
@['/admin/products/:id/options'; post]
pub fn (mut app App) admin_products_id_options_post(mut ctx Context, id string) veb.Result {
	id_bin := id_string_to_bin(id) or {
		return handle_error_400(mut ctx, error_id_invalid, err.msg())
	}

	p := json.decode(ProductOptionRequest, ctx.req.data) or {
		return handle_error_400(mut ctx, 'Could not decode ProductOptionRequest', err.msg())
	}

	if p.translations.len == 0 {
		return handle_error_400(mut ctx, 'product_option must have a title', 'No translations provided')
	}

	ph := hygienise_product_option_request(p) or {
		if err is InternalError {
			return handle_error_400(mut ctx, err.message, err.details)
		}
		return handle_error_500(mut ctx, 'Unhandled error at hygienise_product_option_request',
			err.msg())
	}

	return conduit_product_option_create(mut app, mut ctx, id, id_bin, ph)
}

// updates a product option
@['/admin/products/:product_id/options/:option_id'; post]
pub fn (mut app App) admin_update_product_option(mut ctx Context, product_id string, product_option_id string) veb.Result {
	product_id_bin := id_string_to_bin(product_id) or {
		return handle_error_400(mut ctx, error_id_invalid, err.msg())
	}

	product_option_id_bin := id_string_to_bin(product_option_id) or {
		return handle_error_400(mut ctx, error_id_invalid, err.msg())
	}

	p := json.decode(ProductOptionUpdateRequest, ctx.req.data) or {
		return handle_error_400(mut ctx, 'Could not decode ProductOptionUpdateRequest',
			err.msg())
	}

	if p.translations.len == 0 {
		return handle_error_400(mut ctx, 'product_option must have a title', 'No translations provided')
	}

	ph := hygienise_product_option_update_request(p) or {
		if err is InternalError {
			return handle_error_400(mut ctx, err.message, err.details)
		}
		return handle_error_500(mut ctx, 'Unhandled error at hygienise_product_option_update_request',
			err.msg())
	}

	return conduit_product_option_update(mut app, mut ctx, product_id, product_id_bin,
		product_option_id, product_option_id_bin, ph)
}

// deletes a product option
@['/admin/products/:product_id/options/:product_option_id'; delete]
pub fn (mut app App) admin_product_option_delete(mut ctx Context, product_id string, product_option_id string) veb.Result {
	product_id_bin := id_string_to_bin(product_id) or {
		return handle_error_400(mut ctx, error_id_invalid, err.msg())
	}

	product_option_id_bin := id_string_to_bin(product_option_id) or {
		return handle_error_400(mut ctx, error_id_invalid, err.msg())
	}

	// TODO Product does not exist
	// TODO Option does not exist
	// TODO Can't delete option with multiple values

	return conduit_product_option_delete(mut app, mut ctx, product_id, product_id_bin,
		product_option_id, product_option_id_bin)
}

@['/admin/products/:product_id/options/:product_option_id/values/:product_value_id'; post]
pub fn (mut app App) admin_product_option_value_update(mut ctx Context, product_id string, product_option_id string, product_value_id string) veb.Result {
	return ctx.json('TODO')
}

@['/admin/products/:product_id/options/:product_option_id/values/:product_value_id'; delete]
pub fn (mut app App) admin_product_option_value_delete(mut ctx Context, product_id string, product_option_id string, product_value_id string) veb.Result {
	return ctx.json('TODO')
}
