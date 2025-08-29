module peony

import veb

fn conduit_products_get(mut app App, mut ctx Context, ph RetrieveProductParamsHygienised) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	count := model_product_retrieve_count(mut tx, ph) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Failed to retrieve product count', err.msg())
	}

	offset := get_offset_amount(ph.offset)

	if count == 0 || offset >= count {
		tx.rollback() or {}
		r := ProductResponseListEnvelope{
			products: []ProductResponse{}
			count:    count
			offset:   offset
			fetch:    ph.fetch.v
		}

		return ctx.json(r)
	}

	products := model_product_retrieve(mut tx, ph) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Failed to retrieve product', err.msg())
	}

	mut products_map, product_ids_bin := make_product_map(products)
	mut products_data := suite_product_data_get(mut tx, product_ids_bin) or {
		tx.rollback() or {}
		if err is SuiteError {
			return handle_suite_error(mut ctx, err)
		} else {
			return handle_error_500(mut ctx, 'Unhandled error at suite_product_data_get',
				err.msg())
		}
	}

	tx.rollback() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }

	assign_products_data(mut products_data, mut products_map)

	// new array, using original sorting order
	mut complete_products := []Product{len: products.len}
	for i := 0; i < products.len; i++ {
		id := products[i].id
		complete_products[i] = products_map[id]
	}

	mut external_products := []ProductResponse{len: complete_products.len}
	for i := 0; i < complete_products.len; i++ {
		external_products[i] = format_product_response_admin(complete_products[i]) or {
			return handle_error_500(mut ctx, 'Failed to format response', err.msg())
		}
	}

	r := ProductResponseListEnvelope{
		products: external_products
		count:    count
		offset:   get_offset_amount(ph.offset)
		fetch:    ph.fetch.v
	}

	return ctx.json(r)
}

fn conduit_products_get_store(mut app App, mut ctx Context, ph RetrieveProductParamsHygienised) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	count := model_product_retrieve_count(mut tx, ph) or {
		tx.rollback() or {} // ignore error
		return handle_error_500(mut ctx, 'Failed to retrieve products count', err.msg())
	}

	offset := get_offset_amount(ph.offset)

	if count == 0 || offset >= count {
		tx.rollback() or {}
		r := ProductResponseListEnvelope{
			products: []ProductResponse{}
			count:    count
			offset:   offset
			fetch:    ph.fetch.v
		}

		return ctx.json(r)
	}

	products := model_product_retrieve(mut tx, ph) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Failed to retrieve product', err.msg())
	}

	mut products_map, product_ids_bin := make_product_map(products)
	mut products_data := suite_product_data_get(mut tx, product_ids_bin) or {
		tx.rollback() or {}
		if err is SuiteError {
			return handle_suite_error(mut ctx, err)
		} else {
			return handle_error_500(mut ctx, 'Unhandled error at suite_product_data_get',
				err.msg())
		}
	}

	mut currency_code := ''
	if ph.currency_code.is_set {
		currency_code = ph.currency_code.v
	} else {
		store := do_retrieve_store(mut tx) or {
			tx.rollback() or {} // ignore error
			return handle_error_500(mut ctx, 'Failed to retrieve store data', err.msg())
		}
		currency_code = store.default_currency_code
	}

	tx.rollback() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }

	assign_products_data(mut products_data, mut products_map)

	pctx := PriceContext{
		region_id_bin: ph.region_id_bin
		currency_code: currency_code
		// TODO include_discount_prices
	}

	mut complete_products := []Product{len: products.len}
	for i := 0; i < products.len; i++ {
		id := products[i].id
		complete_products[i] = products_map[id]
	}

	mut variant_prices_map := map[string]Prices{}
	for i := 0; i < complete_products.len; i++ {
		for k := 0; k < complete_products[i].variants.len; k++ {
			variant_prices_map[complete_products[i].variants[k].id] = calculate_price(complete_products[i].variants[k],
				1, pctx)
		}
	}

	mut external_products := []ProductResponse{len: complete_products.len}
	for i := 0; i < complete_products.len; i++ {
		external_products[i] = format_product_response_store(complete_products[i], variant_prices_map) or {
			return handle_error_500(mut ctx, 'Failed to format response', err.msg())
		}
	}

	r := ProductResponseListEnvelope{
		products: external_products
		count:    count
		offset:   get_offset_amount(ph.offset)
		fetch:    ph.fetch.v
	}

	return ctx.json(r)
}

fn conduit_products_get_by_id(mut app App, mut ctx Context, ph RetrieveProductParamsHygienised) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	products := model_product_retrieve(mut tx, ph) or {
		tx.rollback() or {} // ignore error
		return handle_error_500(mut ctx, 'Failed to retrieve products data', err.msg())
	}

	if products.len == 0 {
		return handle_error_404(mut ctx, 'Not found', 'No product exists with the given id')
	}

	mut product := products[0]
	mut product_data := suite_product_data_get(mut tx, [product.id_bin]) or {
		tx.rollback() or {}
		if err is SuiteError {
			return handle_suite_error(mut ctx, err)
		} else {
			return handle_error_500(mut ctx, 'Unhandled error at suite_product_data_get',
				err.msg())
		}
	}

	tx.rollback() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }

	assign_product_data(mut product_data, mut product)

	external_product := format_product_response_admin(product) or {
		return handle_error_500(mut ctx, 'Failed to format response', err.msg())
	}

	r := ProductResponseEnvelope{
		product: external_product
	}

	return ctx.json(r)
}

fn conduit_products_get_by_id_store(mut app App, mut ctx Context, ph RetrieveProductParamsHygienised) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	products := model_product_retrieve(mut tx, ph) or {
		tx.rollback() or {} // ignore error
		return handle_error_500(mut ctx, 'Failed to retrieve products data', err.msg())
	}

	if products.len == 0 {
		return handle_error_404(mut ctx, 'Not found', 'No product exists with the given id')
	}

	mut product := products[0]
	mut product_data := suite_product_data_get(mut tx, [product.id_bin]) or {
		tx.rollback() or {}
		if err is SuiteError {
			return handle_suite_error(mut ctx, err)
		} else {
			return handle_error_500(mut ctx, 'Unhandled error at suite_product_data_get',
				err.msg())
		}
	}

	mut currency_code := ''
	if ph.currency_code.is_set {
		currency_code = ph.currency_code.v
	} else {
		store := do_retrieve_store(mut tx) or {
			tx.rollback() or {} // ignore error
			return handle_error_500(mut ctx, 'Failed to retrieve store data', err.msg())
		}
		currency_code = store.default_currency_code
	}

	tx.rollback() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }

	assign_product_data(mut product_data, mut product)

	pctx := PriceContext{
		// cart_id_bin
		// customer_id_bin
		region_id_bin: ph.region_id_bin
		currency_code: currency_code
		// include_discount_prices
	}

	mut variant_prices_map := map[string]Prices{}
	for k := 0; k < product.variants.len; k++ {
		variant_prices_map[product.variants[k].id] = calculate_price(product.variants[k],
			1, pctx)
	}

	external_product := format_product_response_store(product, variant_prices_map) or {
		return handle_error_500(mut ctx, 'Failed to format response', err.msg())
	}

	r := ProductResponseEnvelope{
		product: external_product
	}

	return ctx.json(r)
}

fn conduit_products_update(mut app App, mut ctx Context, product_id_bin []u8, ph ProductRequestHygienised) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	if ph.handle != none || ph.is_giftcard != none || ph.status != none || ph.thumbnail != none
		|| ph.collection_id != none || ph.type_id != none || ph.discountable != none
		|| ph.metadata != none {
		model_product_update(mut tx, product_id_bin, ph) or {
			tx.rollback() or {} // ignore error
			return handle_error_500(mut ctx, 'Failed to update product', err.msg())
		}
	}

	if _ := ph.tag_ids {
		// TODO
	}

	if images := ph.images {
		model_product_images_update(mut app, mut tx, product_id_bin, images) or {
			tx.rollback() or {}
			return handle_error_500(mut ctx, 'Failed to update product images', err.msg())
		}
	}

	if _ := ph.sales_channel_ids {
		model_product_sales_channel_update(mut tx, product_id_bin, ph.sales_channel_ids_bin) or {
			tx.rollback() or {}
			return handle_error_500(mut ctx, 'Failed to update product sales channel',
				err.msg())
		}
	}

	if _ := ph.category_ids {
		model_product_category_product_update(mut tx, product_id_bin, ph.category_ids_bin) or {
			tx.rollback() or {}
			return handle_error_500(mut ctx, 'Failed to update product category relation',
				err.msg())
		}
	}

	if translations := ph.translations {
		model_product_translation_update(mut tx, product_id_bin, translations) or {
			tx.rollback() or {}
			return handle_error_500(mut ctx, 'Failed to update product translations',
				err.msg())
		}
	}

	tx.commit() or { return handle_error_500(mut ctx, error_transaction_commit, err.msg()) }

	return success(mut ctx)
}

// TODO validate p in route
fn conduit_product_option_create(mut app App, mut ctx Context, product_id string, product_id_bin []u8, ph []ProductOptionTranslationDataHygienised) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	_, product_option_id_bin := app.new_id()

	model_product_option_create(mut tx, product_option_id_bin, product_id_bin) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not create product_option', err.msg())
	}

	model_product_option_update(mut tx, product_option_id_bin, ph) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not create product_option: could not insert translations',
			err.msg())
	}

	vph := RetrieveProductVariantParamsHygienised{
		product_ids:     ZeroArrayString{
			is_set: true
		}
		product_ids_bin: [product_id_bin]
	}

	count := model_product_variants_retrieve_count(mut tx, vph) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not add product_option to product_variants: could not retrieve product_variant count',
			err.msg())
	}

	internal_variants := model_product_variants_retrieve(mut tx, vph) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not add product_option to product_variants: could not retrieve product_variant',
			err.msg())
	}

	if count > 0 {
		mut product_variant_ids_bin := [][]u8{len: internal_variants.len}
		mut product_option_value_ids_bin := [][]u8{len: internal_variants.len}
		for i := 0; i < internal_variants.len; i++ {
			product_variant_ids_bin[i] = internal_variants[i].id_bin
			_, product_option_value_id_bin := app.new_id()
			product_option_value_ids_bin[i] = product_option_value_id_bin
		}
		model_product_option_value_create_default(mut tx, product_option_id_bin, product_option_value_ids_bin,
			product_variant_ids_bin) or {
			tx.rollback() or {} // ignore error
			return handle_error_500(mut ctx, 'Could not add default option value to variant',
				err.msg())
		}
	}

	tx.commit() or { return handle_error_500(mut ctx, error_transaction_commit, err.msg()) }

	return success(mut ctx)
}

fn conduit_product_option_update(mut app App, mut ctx Context, product_id string, product_id_bin []u8, product_option_id string, product_option_id_bin []u8, ph []ProductOptionTranslationDataHygienised) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	model_product_option_update(mut tx, product_option_id_bin, ph) or {
		tx.rollback() or {} // ignore error
		return handle_error_500(mut ctx, 'Could not create product_option: could not insert translations',
			err.msg())
	}

	tx.commit() or { return handle_error_500(mut ctx, error_transaction_commit, err.msg()) }

	return success(mut ctx)
}

// returns an error when attempting to delete options if more than one variant exist
// require user to delete all variants manually first, then allow deletion of any option
fn conduit_product_option_delete(mut app App, mut ctx Context, product_id string, product_id_bin []u8, product_option_id string, product_option_id_bin []u8) veb.Result {
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
		tx.rollback() or {} // ignore error
		return handle_error_500(mut ctx, 'Could not add product_option to product_variants: could not retrieve product_variants',
			err.msg())
	}

	if count > 1 {
		tx.rollback() or {} // ignore error
		return handle_error_400(mut ctx, 'Refusing to delete product_option: first delete all variants',
			'more than one variant exist')
	}

	model_product_option_delete(mut tx, product_option_id_bin) or {
		tx.rollback() or {} // ignore error
		return handle_error_400(mut ctx, 'Could not delete product_option', err.msg())
	}

	tx.commit() or { return handle_error_500(mut ctx, error_transaction_commit, err.msg()) }

	return success(mut ctx)
}
