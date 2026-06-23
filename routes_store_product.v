module peony

import veb
import einar_hjortdal.firebird
import internal.conduit
import internal.errors

// lists products
// TODO cache response. I don't think this can be cached easily: need to normalize parameters.
@['/store/products'; get]
pub fn (mut app App) store_products_get(mut ctx Context) veb.Result {
	api_key := ctx.get_api_key() or { return ctx.handle_error(err) }
	lctx := app.get_locale_context(ctx.query) or { return ctx.handle_error(err) }
	pctx := app.get_price_context(ctx.query) or { return ctx.handle_error(err) }

	p := hygienise_product_list_query_params_store(ctx.query, api_key.sales_channel_id) or {
		return ctx.handle_error(err)
	}

	data := app.with_rollback(fn [p] (mut tx firebird.ClientTransaction) !ListReturn {
		if _ := pctx.cart_id {
			// TODO check is valid
		}

		count := conduit.product_list_count(mut tx, p)!
		if count == 0 {
			return ListReturn{}
		}

		products := conduit.product_list(mut tx, p)!
		return ListReturn{
			count: count
			items: products
		}
	}) or { return ctx.handle_error(err) }

	if data.count == 0 {
		return ctx.handle_ok(ProductResponseStoreListEnvelope{
			offset: p.offset
			fetch:  p.fetch
		})
	}

	return ctx.handle_ok(ProductResponseStoreListEnvelope{
		products: format_product_response_store_list(data.items, pctx, api_key.sales_channel_id,
			variants_availability, lctx)
		count:    data.count
		offset:   p.offset
		fetch:    p.fetch
	})
}

// get product by id
// TODO cache response. I don't think this can be cached easily: need to normalize parameters.
@['/store/products/:product_id'; get]
pub fn (mut app App) store_products_get_by_id(mut ctx Context, product_id string) veb.Result {
	parsed_product_id := id_from_string(product_id) or {
		return ctx.handle_error(errors.bad_request(error_id_invalid, 'product_id'))
	}

	api_key := ctx.get_api_key() or { return ctx.handle_error(err) }
	lctx := app.get_locale_context(ctx.query) or { return ctx.handle_error(err) }
	pctx := app.get_price_context(ctx.query) or { return ctx.handle_error(err) }

	product := app.with_rollback(fn [mut app, api_key, parsed_product_id] (mut tx firebird.ClientTransaction) !conduit.Product {
		if _ := pctx.cart_id {
			// TODO check is valid
		}

		return conduit.product_get_store(mut tx, parsed_product_id, api_key.sales_channel_id)
	}) or { return ctx.handle_error(err) }

	return ctx.handle_ok(ProductResponseStoreEnvelope{
		product: format_product_response_store(data.product, pctx, api_key.sales_channel_id, lctx)
	})
}
