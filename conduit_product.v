module peony

import veb

fn conduit_product_create(mut app App, mut ctx Context, ph ProductRequestHygienised) veb.Result {
	product_id, product_id_bin := app.new_id()
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	model_product_create(mut tx, product_id, product_id_bin, ph) or {
		tx.rollback() or {} // ignore error
		return handle_error_500(mut ctx, 'Failed to create product', err.msg())
	}

	store := model_store_retrieve(mut tx) or {
		tx.rollback() or {} // ignore error
		return handle_error_500(mut ctx, 'Failed to retrieve store', err.msg())
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
			return handle_error_500(mut ctx, 'Failed to update product_sales_channel',
				err.msg())
		}
	} else {
		model_product_sales_channel_update(mut tx, product_id_bin, [
			store.default_sales_channel_id_bin,
		]) or {
			tx.rollback() or {}
			return handle_error_500(mut ctx, 'Failed to update product_sales_channel',
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
		if err is InternalError {
			return handle_suite_error(mut ctx, err)
		} else {
			return handle_error_500(mut ctx, 'Unhandled error at suite_product_data_get',
				err.msg())
		}
	}

	mut sales_channel_ids_bin := [][]u8{len: products_data.sales_channels.len}
	for i := 0; i < products_data.sales_channels.len; i++ {
		sales_channel_ids_bin[i] = products_data.sales_channels[i].id_bin
	}
	model_sales_channel_stock_location_retrieve_params := ModelSalesChannelStockLocationRetrieveParams{
		sales_channel_ids_bin: sales_channel_ids_bin
	}
	sales_channel_stock_locations := model_sales_channel_stock_location_retrieve(mut tx,
		model_sales_channel_stock_location_retrieve_params) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Failed to retrieve sales_channel_stock_location',
			err.msg())
	}

	tx.rollback() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }

	assign_products_data(mut products_data, mut products_map)

	// new array, using original sorting order
	mut complete_products := []Product{len: products.len}
	for i := 0; i < products.len; i++ {
		id := products[i].id
		complete_products[i] = products_map[id]
	}

	mut complete_product_variants := []ProductVariant{len: products_data.product_variants.len}
	for i := 0; i < products_data.product_variants.len; i++ {
		variant_id := products_data.product_variants[i].id
		variant := products_data.product_variants_map[variant_id]
		complete_product_variants[i] = variant
	}

	get_product_variants_availability_params := GetProductVariantsAvailabilityParams{
		product_sales_channels:        products_data.product_sales_channels
		sales_channel_stock_locations: sales_channel_stock_locations
	}
	product_variants_availability := get_product_variants_availability(complete_product_variants,
		ph.sales_channel_ids_bin, get_product_variants_availability_params)

	mut external_products := []ProductResponse{len: complete_products.len}
	for i := 0; i < complete_products.len; i++ {
		external_products[i] = format_product_response_admin(complete_products[i], product_variants_availability) or {
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
		if err is InternalError {
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
		store := model_store_retrieve(mut tx) or {
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
		external_products[i] = format_product_response_store(complete_products[i], pctx) or {
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
		if err is InternalError {
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
		if err is InternalError {
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
		store := model_store_retrieve(mut tx) or {
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

	external_product := format_product_response_store(product, pctx) or {
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

fn conduit_product_delete(mut app App, mut ctx Context, product_id_bin []u8) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	model_product_delete(mut tx, product_id_bin) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Failed to delete product', err.msg())
	}

	tx.commit() or { return handle_error_500(mut ctx, error_transaction_commit, err.msg()) }

	return success(mut ctx)
}

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
