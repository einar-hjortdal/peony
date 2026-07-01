module peony

import json
import veb
import einar_hjortdal.firebird
import internal.common
import internal.conduit
import internal.errors

// lists products
@['/admin/products'; get]
pub fn (mut app App) admin_product_list(mut ctx Context) veb.Result {
	p := hygienise_product_list_query_params(ctx.query) or { return ctx.handle_error(err) }

	data := app.with_rollback(fn [p] (mut tx firebird.ClientTransaction) !conduit.List[conduit.Product] {
		return conduit.product_list(mut tx, p)
	}) or { return ctx.handle_error(err) }

	return ctx.handle_ok(ProductResponseListEnvelope{
		products: format_product_list_response(data.items)
		count:    data.count
		offset:   p.offset
		fetch:    p.fetch
	})
}

// create a product
@['/admin/products'; post]
pub fn (mut app App) admin_product_create(mut ctx Context) veb.Result {
	decoded := json.decode(ProductCreateRequest, ctx.req.data) or {
		return ctx.handle_error(errors.bad_request('Could not decode ProductRequest', err.msg()))
	}

	p := decoded.hygienise() or { return ctx.handle_error(err) }

	product := app.with_commit(fn [mut app, p] (mut tx firebird.ClientTransaction) !conduit.Product {
		product_id := conduit.product_create(mut tx, mut app.luuid_generator, p)!
		return conduit.product_get(mut tx, product_id)
	}) or { return ctx.handle_error(err) }

	return ctx.handle_created(ProductResponseEnvelope{
		product: format_product_response(product)
	})
}

// get a product by id
@['/admin/products/:product_id'; get]
pub fn (mut app App) admin_product_get(mut ctx Context, product_id string) veb.Result {
	parsed_product_id := id_from_string(product_id) or {
		return ctx.handle_error(errors.unprocessable_entity(errors.id_invalid, 'product_id'))
	}

	product := app.with_rollback(fn [parsed_product_id] (mut tx firebird.ClientTransaction) !conduit.Product {
		return conduit.product_get(mut tx, parsed_product_id)
	}) or { return ctx.handle_error(err) }

	return ctx.handle_created(ProductResponseEnvelope{
		product: format_product_response(product)
	})
}

// updates a product
@['/admin/products/:product_id'; post]
pub fn (mut app App) admin_product_update(mut ctx Context, product_id string) veb.Result {
	parsed_product_id := id_from_string(product_id) or {
		return ctx.handle_error(errors.unprocessable_entity(errors.id_invalid, 'product_id'))
	}

	encoded := json.decode(ProductUpdateRequest, ctx.req.data) or {
		perr := errors.bad_request('Could not decode ProductUpdateRequest', err.msg())
		return ctx.handle_error(perr)
	}

	p := encoded.hygienise(parsed_product_id) or { return ctx.handle_error(err) }

	product := app.with_commit(fn [mut app, p, parsed_product_id] (mut tx firebird.ClientTransaction) !conduit.Product {
		conduit.product_update(mut tx, mut app.luuid_generator, p)!
		return conduit.product_get(mut tx, parsed_product_id)
	}) or { return ctx.handle_error(err) }

	return ctx.handle_ok(ProductResponseEnvelope{
		product: format_product_response(product)
	})
}

// deletes a product
@['/admin/products/:product_id'; delete]
pub fn (mut app App) admin_products_id_delete(mut ctx Context, product_id string) veb.Result {
	parsed_product_id := id_from_string(product_id) or {
		return ctx.handle_error(errors.bad_request(errors.id_invalid, 'product_id'))
	}

	app.with_commit(fn [parsed_product_id] (mut tx firebird.ClientTransaction) !common.Empty {
		conduit.product_delete(mut tx, parsed_product_id)!
		return common.Empty{}
	}) or { return ctx.handle_error(err) }

	return ctx.handle_deleted()
}

// creates a variant
@['/admin/products/:product_id/variants/'; post]
pub fn (mut app App) variant_create(mut ctx Context, product_id string) veb.Result {
	parsed_product_id := id_from_string(product_id) or {
		return ctx.handle_error(errors.unprocessable_entity(errors.id_invalid, 'product_id'))
	}

	decoded := json.decode(VariantCreateRequest, ctx.req.data) or {
		return ctx.handle_error(errors.bad_request('Could not decode VariantCreateRequest ',
			err.msg()))
	}

	p := decoded.hygienise(parsed_product_id) or { return ctx.handle_error(err) }

	variant := app.with_commit(fn [mut app, p] (mut tx firebird.ClientTransaction) !conduit.Variant {
		variant_id := conduit.variant_create(mut tx, mut app.luuid_generator, p)!
		return conduit.variant_get(mut tx, variant_id)
	}) or { return ctx.handle_error(err) }

	return ctx.handle_created(VariantResponseEnvelope{
		variant: format_variant_response(variant)
	})
}

// updates a variant
@['/admin/products/:product_id/variants/:variant_id'; post]
pub fn (mut app App) admin_variants_id_post(mut ctx Context, product_id string, variant_id string) veb.Result {
	parsed_product_id := id_from_string(product_id) or {
		return ctx.handle_error(errors.bad_request(errors.id_invalid, 'product_id'))
	}

	parsed_variant_id := id_from_string(variant_id) or {
		return ctx.handle_error(errors.bad_request(errors.id_invalid, 'variant_id'))
	}

	decoded := json.decode(VariantUpdateRequest, ctx.req.data) or {
		return ctx.handle_error(errors.bad_request('Could not decode VariantRequest', err.msg()))
	}

	p := decoded.hygienise(parsed_product_id, parsed_variant_id) or { return ctx.handle_error(err) }

	variant := app.with_commit(fn [mut app, p, parsed_variant_id] (mut tx firebird.ClientTransaction) !conduit.Variant {
		conduit.variant_update(mut tx, mut app.luuid_generator, p)!
		return conduit.variant_get(mut tx, parsed_variant_id)
	}) or { return ctx.handle_error(err) }

	return ctx.handle_ok(VariantResponseEnvelope{
		variant: format_variant_response(variant)
	})
}

// deletes a variant
@['/admin/products/:product_id/variants/:variant_id'; delete]
pub fn (mut app App) variant_delete(mut ctx Context, product_id string, variant_id string) veb.Result {
	parsed_product_id := id_from_string(product_id) or {
		return ctx.handle_error(errors.bad_request(errors.id_invalid, 'product_id'))
	}

	parsed_variant_id := id_from_string(variant_id) or {
		return ctx.handle_error(errors.bad_request(errors.id_invalid, 'variant_id'))
	}

	app.with_commit(fn [parsed_product_id, parsed_variant_id] (mut tx firebird.ClientTransaction) !common.Empty {
		conduit.variant_delete(mut tx, parsed_product_id, parsed_variant_id)!
		return common.Empty{}
	}) or { return ctx.handle_error(err) }

	return ctx.handle_deleted()
}

// creates a new product image
@['/admin/products/:product_id/images'; post]
pub fn (mut app App) product_image_create(mut ctx Context, product_id string) veb.Result {
	parsed_product_id := id_from_string(product_id) or {
		return ctx.handle_error(errors.bad_request(errors.id_invalid, 'product_id'))
	}

	decoded := json.decode(ImageCreateRequest, ctx.req.data) or {
		return ctx.handle_error(errors.bad_request('Could not decode ImageCreateRequest', err.msg()))
	}

	p := decoded.hygienise() or { return ctx.handle_error(err) }

	image := app.with_commit(fn [mut app, p, parsed_product_id] (mut tx firebird.ClientTransaction) !conduit.ProductImage {
		image_id := conduit.product_image_create(mut tx, mut app.luuid_generator,
			parsed_product_id, p)!
		return conduit.product_image_get(mut tx, parsed_product_id, image_id)
	}) or { return ctx.handle_error(err) }

	return ctx.handle_ok(ProductImageResponseEnvelope{
		image: format_product_image_response(image)
	})
}

// retrieves a product image
@['/admin/products/:product_id/images/:image_id'; get]
pub fn (mut app App) product_image_get(mut ctx Context, product_id string, image_id string) veb.Result {
	parsed_product_id := id_from_string(product_id) or {
		return ctx.handle_error(errors.bad_request(errors.id_invalid, 'product_id'))
	}

	parsed_image_id := id_from_string(image_id) or {
		return ctx.handle_error(errors.bad_request(errors.id_invalid, 'image_id'))
	}

	image := app.with_commit(fn [parsed_product_id, parsed_image_id] (mut tx firebird.ClientTransaction) !conduit.ProductImage {
		return conduit.product_image_get(mut tx, parsed_product_id, parsed_image_id)
	}) or { return ctx.handle_error(err) }

	return ctx.handle_ok(ProductImageResponseEnvelope{
		image: format_product_image_response(image)
	})
}

// updates a product image
@['/admin/products/:product_id/images/:image_id'; post]
pub fn (mut app App) product_image_update(mut ctx Context, product_id string, image_id string) veb.Result {
	parsed_product_id := id_from_string(product_id) or {
		return ctx.handle_error(errors.bad_request(errors.id_invalid, 'product_id'))
	}

	parsed_image_id := id_from_string(image_id) or {
		return ctx.handle_error(errors.bad_request(errors.id_invalid, 'image_id'))
	}

	decoded := json.decode(ImageUpdateRequest, ctx.req.data) or {
		return ctx.handle_error(errors.bad_request('Could not decode ImageUpdateRequest', err.msg()))
	}

	p := decoded.hygienise(parsed_image_id) or { return ctx.handle_error(err) }

	image := app.with_commit(fn [parsed_product_id, parsed_image_id, p] (mut tx firebird.ClientTransaction) !conduit.ProductImage {
		conduit.product_image_update(mut tx, p)!
		return conduit.product_image_get(mut tx, parsed_product_id, parsed_image_id)
	}) or { return ctx.handle_error(err) }

	return ctx.handle_ok(ProductImageResponseEnvelope{
		image: format_product_image_response(image)
	})
}

// deletes a product image
@['/admin/products/:product_id/images/:image_id'; delete]
pub fn (mut app App) product_image_delete(mut ctx Context, product_id string, image_id string) veb.Result {
	parsed_product_id := id_from_string(product_id) or {
		return ctx.handle_error(errors.bad_request(errors.id_invalid, 'product_id'))
	}

	parsed_image_id := id_from_string(image_id) or {
		return ctx.handle_error(errors.bad_request(errors.id_invalid, 'image_id'))
	}

	app.with_commit(fn [parsed_product_id, parsed_image_id] (mut tx firebird.ClientTransaction) !common.Empty {
		conduit.product_image_delete(mut tx, parsed_product_id, parsed_image_id)!
		return common.Empty{}
	}) or { return ctx.handle_error(err) }

	return ctx.handle_deleted()
}
