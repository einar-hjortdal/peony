module main

import net.http
import veb

fn conduit_products_get_list(mut app App, mut ctx Context, p RetrieveProductParams) veb.Result {
	internal_products, count := app.retrieve_products(p) or {
		return handle_error(mut ctx, http.Status.internal_server_error, 'Failed to retrieve products data',
			err.msg())
	}

	// TODO validation moved to route_
	mut region_id_bin := []u8{}
	if p.region_id.is_set {
		region_id_bin = id_string_to_bin(p.region_id.v) or {
			ctx.res.set_status(http.Status.bad_request)
			return ctx.json(new_peony_error('Invalid region_id', err.msg()))
		}
	}

	mut currency_code := ''
	if p.currency_code.is_set {
		currency_code = p.currency_code.v
	} else {
		store := app.store_retrieve() or {
			ctx.res.set_status(http.Status.internal_server_error)
			return ctx.json(new_peony_error('Failed to retrieve store data', err.msg()))
		}
		currency_code = store.default_currency_code
	}

	pctx := PriceContext{
		// TODO cart_id_bin
		// TODO get customer_id from ctx if customer is logged in
		region_id_bin: region_id_bin
		currency_code: currency_code
		// TODO include_discount_prices
	}

	mut variant_prices_map := map[string]Prices{}
	for i := 0; i < internal_products.len; i++ {
		for k := 0; k < internal_products[i].variants.len; k++ {
			variant_prices_map[internal_products[i].variants[k].id] = calculate_price(internal_products[i].variants[k],
				1, pctx)
		}
	}

	mut external_products := []ProductResponse{len: internal_products.len}
	for i := 0; i < internal_products.len; i++ {
		external_products[i] = format_product_response(internal_products[i], variant_prices_map) or {
			ctx.res.set_status(http.Status.internal_server_error)
			return ctx.json(new_peony_error('Failed to format response', err.msg()))
		}
	}

	r := ListResponse{
		items:  external_products
		count:  count
		offset: get_offset_amount(p.offset)
		fetch:  get_fetch_amount(p.fetch)
	}

	return ctx.json(r)
}

fn conduit_products_get_by_id(mut app App, mut ctx Context, p RetrieveProductParams) veb.Result {
	internal_products, count := app.retrieve_products(p) or {
		return handle_error(mut ctx, http.Status.internal_server_error, 'Failed to retrieve products data',
			err.msg())
	}

	if count == 0 {
		return handle_error(mut ctx, http.Status.not_found, 'Not found', 'No product exists with the given id')
	}

	// TODO validation moved to route_
	mut region_id_bin := []u8{}
	if p.region_id.is_set {
		region_id_bin = id_string_to_bin(p.region_id.v) or {
			ctx.res.set_status(http.Status.bad_request)
			return ctx.json(new_peony_error('Invalid region_id', err.msg()))
		}
	}

	mut currency_code := ''
	if p.currency_code.is_set {
		currency_code = p.currency_code.v
	} else {
		store := app.store_retrieve() or {
			ctx.res.set_status(http.Status.internal_server_error)
			return ctx.json(new_peony_error('Failed to retrieve store data', err.msg()))
		}
		currency_code = store.default_currency_code
	}

	pctx := PriceContext{
		// TODO cart_id_bin
		// TODO get customer_id from ctx if customer is logged in
		region_id_bin: region_id_bin
		currency_code: currency_code
		// TODO include_discount_prices
	}

	mut variant_prices_map := map[string]Prices{}
	for i := 0; i < internal_products[0].variants.len; i++ {
		variant_prices_map[internal_products[0].variants[i].id] = calculate_price(internal_products[0].variants[i],
			1, pctx)
	}

	external_product := format_product_response(internal_products[0], variant_prices_map) or {
		return handle_error(mut ctx, http.Status.internal_server_error, 'Failed to format response',
			err.msg())
	}

	return ctx.json(external_product)
}

// TODO return error when attempting to delete options that are used by some variant
// TODO when option is created, give all existing variants a deffault option value
fn conduit_products_update(mut app App, mut ctx Context, id_bin []u8, p ProductData) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error(mut ctx, http.Status.internal_server_error, error_transaction_start,
			err.msg())
	}

	app.do_update_product(mut tx, id_bin, p) or {
		tx.rollback() or {} // ignore error
		return handle_error(mut ctx, http.Status.internal_server_error, 'Failed to update product',
			err.msg())
	}

	tx.commit() or {
		return handle_error(mut ctx, http.Status.internal_server_error, error_transaction_commit,
			err.msg())
	}

	return ctx.json(new_peony_success())
}
