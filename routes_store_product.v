module peony

import veb
import einar_hjortdal.firebird
import internal.common
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

	data := app.with_rollback(fn [p] (mut tx firebird.ClientTransaction) !conduit.List[conduit.Product] {
		return conduit.product_list(mut tx, p)
	}) or { return ctx.handle_error(err) }

	return ctx.handle_ok(ProductResponseStoreListEnvelope{
		products: format_product_response_store_list(data.items, pctx, api_key.sales_channel_id,
			lctx)
		count:    data.count
		offset:   p.offset
		fetch:    p.fetch
	})
}

// get product by id
// TODO cache response. I don't think this can be cached easily: need to normalize parameters.
@['/store/products/:product_id'; get]
pub fn (mut app App) store_products_get_by_id(mut ctx Context, product_id string) veb.Result {
	parsed_product_id := common.id_from_string(product_id) or {
		return ctx.handle_error(errors.bad_request(errors.id_invalid, 'product_id'))
	}

	api_key := ctx.get_api_key() or { return ctx.handle_error(err) }
	lctx := app.get_locale_context(ctx.query) or { return ctx.handle_error(err) }
	pctx := app.get_price_context(ctx.query) or { return ctx.handle_error(err) }

	product := app.with_rollback(fn [api_key, parsed_product_id] (mut tx firebird.ClientTransaction) !conduit.Product {
		return conduit.product_get_store(mut tx, parsed_product_id, api_key.sales_channel_id)
	}) or { return ctx.handle_error(err) }

	return ctx.handle_ok(ProductResponseStoreEnvelope{
		product: format_product_response_store(product, pctx, api_key.sales_channel_id, lctx)
	})
}
