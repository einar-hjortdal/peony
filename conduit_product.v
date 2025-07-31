module peony

import net.http
import veb

fn conduit_products_get(mut app App, mut ctx Context, ph RetrieveProductParamsHygienised) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error(mut ctx, http.Status.internal_server_error, error_transaction_start,
			err.msg())
	}

	internal_products, count := retrieve_products(mut tx, ph) or {
		tx.rollback() or {} // ignore error
		return handle_error(mut ctx, http.Status.internal_server_error, 'Failed to retrieve products data',
			err.msg())
	}

	tx.rollback() or {
		return handle_error(mut ctx, http.Status.internal_server_error, error_transaction_rollback,
			err.msg())
	}

	mut external_products := []ProductResponse{len: internal_products.len}
	for i := 0; i < internal_products.len; i++ {
		external_products[i] = format_product_response_admin(internal_products[i]) or {
			ctx.res.set_status(http.Status.internal_server_error)
			return ctx.json(new_peony_error('Failed to format response', err.msg()))
		}
	}

	r := ProductResponseListEnvelope{
		products: external_products
		count:    count
		offset:   get_offset_amount(ph.offset)
		fetch:    get_fetch_amount(ph.fetch)
	}

	return ctx.json(r)
}

fn conduit_products_get_store(mut app App, mut ctx Context, ph RetrieveProductParamsHygienised) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error(mut ctx, http.Status.internal_server_error, error_transaction_start,
			err.msg())
	}

	internal_products, count := retrieve_products(mut tx, ph) or {
		tx.rollback() or {} // ignore error
		return handle_error(mut ctx, http.Status.internal_server_error, 'Failed to retrieve products data',
			err.msg())
	}

	mut currency_code := ''
	if ph.currency_code.is_set {
		currency_code = ph.currency_code.v
	} else {
		store := do_retrieve_store(mut tx) or {
			tx.rollback() or {} // ignore error
			ctx.res.set_status(http.Status.internal_server_error)
			return ctx.json(new_peony_error('Failed to retrieve store data', err.msg()))
		}
		currency_code = store.default_currency_code
	}

	tx.rollback() or {
		return handle_error(mut ctx, http.Status.internal_server_error, error_transaction_rollback,
			err.msg())
	}

	pctx := PriceContext{
		region_id_bin: ph.region_id_bin
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
		external_products[i] = format_product_response_store(internal_products[i], variant_prices_map) or {
			ctx.res.set_status(http.Status.internal_server_error)
			return ctx.json(new_peony_error('Failed to format response', err.msg()))
		}
	}

	r := ProductResponseListEnvelope{
		products: external_products
		count:    count
		offset:   get_offset_amount(ph.offset)
		fetch:    get_fetch_amount(ph.fetch)
	}

	return ctx.json(r)
}

fn conduit_products_get_by_id(mut app App, mut ctx Context, ph RetrieveProductParamsHygienised) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error(mut ctx, http.Status.internal_server_error, error_transaction_start,
			err.msg())
	}

	internal_products, count := retrieve_products(mut tx, ph) or {
		tx.rollback() or {} // ignore error
		return handle_error(mut ctx, http.Status.internal_server_error, 'Failed to retrieve products data',
			err.msg())
	}

	tx.rollback() or {
		return handle_error(mut ctx, http.Status.internal_server_error, error_transaction_rollback,
			err.msg())
	}

	if count == 0 {
		return handle_error(mut ctx, http.Status.not_found, 'Not found', 'No product exists with the given id')
	}

	external_product := format_product_response_admin(internal_products[0]) or {
		return handle_error(mut ctx, http.Status.internal_server_error, 'Failed to format response',
			err.msg())
	}

	r := ProductResponseEnvelope{
		product: external_product
	}

	return ctx.json(r)
}

fn conduit_products_get_by_id_store(mut app App, mut ctx Context, ph RetrieveProductParamsHygienised) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error(mut ctx, http.Status.internal_server_error, error_transaction_start,
			err.msg())
	}

	internal_products, count := retrieve_products(mut tx, ph) or {
		tx.rollback() or {} // ignore error
		return handle_error(mut ctx, http.Status.internal_server_error, 'Failed to retrieve products data',
			err.msg())
	}

	mut currency_code := ''
	if ph.currency_code.is_set {
		currency_code = ph.currency_code.v
	} else {
		store := do_retrieve_store(mut tx) or {
			tx.rollback() or {} // ignore error
			ctx.res.set_status(http.Status.internal_server_error)
			return ctx.json(new_peony_error('Failed to retrieve store data', err.msg()))
		}
		currency_code = store.default_currency_code
	}

	tx.rollback() or {
		return handle_error(mut ctx, http.Status.internal_server_error, error_transaction_rollback,
			err.msg())
	}

	if count == 0 {
		return handle_error(mut ctx, http.Status.not_found, 'Not found', 'No product exists with the given id')
	}

	pctx := PriceContext{
		// cart_id_bin
		// customer_id_bin
		region_id_bin: ph.region_id_bin
		currency_code: currency_code
		// include_discount_prices
	}

	mut variant_prices_map := map[string]Prices{}
	for i := 0; i < internal_products.len; i++ {
		for k := 0; k < internal_products[i].variants.len; k++ {
			variant_prices_map[internal_products[i].variants[k].id] = calculate_price(internal_products[i].variants[k],
				1, pctx)
		}
	}

	external_product := format_product_response_store(internal_products[0], variant_prices_map) or {
		return handle_error(mut ctx, http.Status.internal_server_error, 'Failed to format response',
			err.msg())
	}

	r := ProductResponseEnvelope{
		product: external_product
	}

	return ctx.json(r)
}

// TODO return error when attempting to delete options that are used by some variant
// TODO when option is created, give all existing variants a deffault option value
fn conduit_products_update(mut app App, mut ctx Context, product_id_bin []u8, p ProductData) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error(mut ctx, http.Status.internal_server_error, error_transaction_start,
			err.msg())
	}

	app.do_update_product(mut tx, product_id_bin, p) or {
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

// TODO validate p in route
fn conduit_product_option_create(mut app App, mut ctx Context, product_id_bin []u8, p ProductOptionRequest) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error(mut ctx, http.Status.internal_server_error, error_transaction_start,
			err.msg())
	}

	_, id_bin := app.new_id() or {
		return handle_error(mut ctx, http.Status.internal_server_error, error_id_generation,
			err.msg())
	}

	model_product_option_create(mut tx, id_bin, product_id_bin) or {
		tx.rollback() or {} // ignore error
		return handle_error(mut ctx, http.Status.internal_server_error, 'Could not create product_option',
			err.msg())
	}

	model_product_option_update(mut tx, id_bin, p) or {
		tx.rollback() or {} // ignore error
		return handle_error(mut ctx, http.Status.internal_server_error, 'Could not create product_option: could not insert translations',
			err.msg())
	}

	product_variants, count := model_product_variants_retrieve(mut tx) or {
		tx.rollback() or {} // ignore error
		return handle_error(mut ctx, http.Status.internal_server_error, 'Could not add product_option to product_variants: could not retrieve product_variants',
			err.msg())
	}

	if count > 0 {
		// TODO add option to variants, add 'default value' product_option_value
	}

	tx.commit() or {
		return handle_error(mut ctx, http.Status.internal_server_error, error_transaction_commit,
			err.msg())
	}

	return ctx.json(new_peony_success())
}
