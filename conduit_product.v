module peony

import veb

fn conduit_product_create(mut app App, mut ctx Context, ph ProductCreateRequestHygienised) veb.Result {
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

	regions := model_region_retrieve(mut tx, RegionRetriveParams{}) or {
		tx.rollback() or {} // ignore error
		return handle_error_500(mut ctx, 'Failed to retrieve regions', err.msg())
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

	if seo_translations := ph.seo_translations {
		mut seo_translation_ids_bin := [][]u8{len: seo_translations.len}
		for i := 0; i < seo_translations.len; i++ {
			_, seo_translation_ids_bin[i] = app.new_id()
		}

		p := ProductSEOUpdateParams{
			product_id_bin:          product_id_bin
			seo_translation_ids_bin: seo_translation_ids_bin
			seo_translations:        seo_translations
		}

		model_product_seo_update(mut tx, p) or {
			tx.rollback() or {}
			return handle_error_500(mut ctx, 'Failed to update product seo translations',
				err.msg())
		}
	}

	_, variant_id_bin := app.new_id()
	mut region_ids_bin := [][]u8{len: regions.len}
	mut money_amount_ids_bin := [][]u8{len: regions.len}
	for i := 0; i < regions.len; i++ {
		region_ids_bin[i] = regions[i].id_bin
		_, money_amount_ids_bin[i] = app.new_id()
	}

	ma_p := VariantMoneyAmountCreateDefaultParams{
		variant_id_bin:       variant_id_bin
		region_ids_bin:       region_ids_bin
		money_amount_ids_bin: money_amount_ids_bin
	}

	if product_options := ph.options {
		model_variant_create_default_with_options(mut app, mut tx, product_id_bin, variant_id_bin,
			product_options) or {
			tx.rollback() or {}
			return handle_error_500(mut ctx, 'Failed to create default product_variant with provided options',
				err.msg())
		}
	} else {
		_, option_id_bin := app.new_id()
		_, option_value_id_bin := app.new_id()
		_, inventory_item_id_bin := app.new_id()
		pv_p := VariantCreateDefaultParams{
			product_id_bin:        product_id_bin
			variant_id_bin:        variant_id_bin
			option_id_bin:         option_id_bin
			option_value_id_bin:   option_value_id_bin
			inventory_item_id_bin: inventory_item_id_bin
		}

		model_variant_create_default(mut tx, pv_p) or {
			tx.rollback() or {}
			return handle_error_500(mut ctx, 'Failed to create default product_variant',
				err.msg())
		}
	}

	model_product_variant_money_amount_create_default(mut tx, ma_p) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Failed to create default money_amount', err.msg())
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
		tx.rollback() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }
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
		}
		return handle_error_500(mut ctx, 'Unhandled error at suite_product_data_get',
			err.msg())
	}

	// product_variants_availability
	sales_channel_ids_bin := get_sales_channel_ids_bin(products_data.sales_channels)
	model_sales_channel_stock_location_retrieve_params := ModelSalesChannelStockLocationRetrieveParams{
		sales_channel_ids_bin: sales_channel_ids_bin
	}
	sales_channel_stock_locations := model_sales_channel_stock_location_retrieve(mut tx,
		model_sales_channel_stock_location_retrieve_params) or {
		tx.rollback() or {}
		if err is InternalError {
			return handle_error_500(mut ctx, err.message, err.details)
		}
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

	// product_variants_availability
	mut complete_product_variants := []ProductVariant{len: products_data.product_variants.len}
	for i := 0; i < products_data.product_variants.len; i++ {
		variant_id := products_data.product_variants[i].id
		complete_product_variants[i] = products_data.product_variants_map[variant_id]
	}

	product_variants_availability := get_product_variants_availability(GetProductVariantsAvailabilityParams{
		product_variants:              complete_product_variants
		sales_channel_ids_bin:         ph.sales_channel_ids_bin
		product_sales_channels:        products_data.product_sales_channels
		sales_channel_stock_locations: sales_channel_stock_locations
	})

	mut external_products := []ProductResponse{len: complete_products.len}
	for i := 0; i < complete_products.len; i++ {
		external_products[i] = format_product_response_admin(complete_products[i], product_variants_availability)
	}

	return ctx.json(ProductResponseListEnvelope{
		products: external_products
		count:    count
		offset:   get_offset_amount(ph.offset)
		fetch:    ph.fetch.v
	})
}

// TODO: store endpoints do not need all the data admin endpoints need.
// do not fetch translations
// do not fetch sales channels
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
		tx.rollback() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }
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
		}
		return handle_error_500(mut ctx, 'Unhandled error at suite_product_data_get',
			err.msg())
	}

	// product_variants_availability
	sales_channel_ids_bin := get_sales_channel_ids_bin(products_data.sales_channels)
	model_sales_channel_stock_location_retrieve_params := ModelSalesChannelStockLocationRetrieveParams{
		sales_channel_ids_bin: sales_channel_ids_bin
	}
	sales_channel_stock_locations := model_sales_channel_stock_location_retrieve(mut tx,
		model_sales_channel_stock_location_retrieve_params) or {
		tx.rollback() or {}
		if err is InternalError {
			return handle_error_500(mut ctx, err.message, err.details)
		}
		return handle_error_500(mut ctx, 'Failed to retrieve sales_channel_stock_location',
			err.msg())
	}

	tx.rollback() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }

	assign_products_data(mut products_data, mut products_map)

	pctx := PriceContext{
		region_id_bin: ph.region_id_bin
	}

	mut complete_products := []Product{len: products.len}
	for i := 0; i < products.len; i++ {
		id := products[i].id
		complete_products[i] = products_map[id]
	}

	// product_variants_availability + prices
	mut variant_prices_map := map[string]ProductVariantPrice{}
	mut complete_product_variants := []ProductVariant{len: products_data.product_variants.len}
	for i := 0; i < products_data.product_variants.len; i++ {
		variant := products_data.product_variants[i]
		complete_product_variants[i] = products_data.product_variants_map[variant.id]
		variant_prices_map[variant.id] = calculate_price(variant, 1, pctx)
	}

	product_variants_availability := get_product_variants_availability(GetProductVariantsAvailabilityParams{
		product_variants:              complete_product_variants
		sales_channel_ids_bin:         ph.sales_channel_ids_bin
		product_sales_channels:        products_data.product_sales_channels
		sales_channel_stock_locations: sales_channel_stock_locations
	})

	mut external_products := []ProductResponse{len: complete_products.len}
	for i := 0; i < complete_products.len; i++ {
		external_products[i] = format_product_response_store(complete_products[i], pctx,
			product_variants_availability)
	}

	return ctx.json(ProductResponseListEnvelope{
		products: external_products
		count:    count
		offset:   get_offset_amount(ph.offset)
		fetch:    ph.fetch.v
	})
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
		tx.rollback() or {} // ignore error
		return handle_error_404(mut ctx, 'Not found', 'No product exists with the given id')
	}

	mut product := products[0]
	mut product_data := suite_product_data_get(mut tx, [product.id_bin]) or {
		tx.rollback() or {}
		if err is InternalError {
			return handle_suite_error(mut ctx, err)
		}
		return handle_error_500(mut ctx, 'Unhandled error at suite_product_data_get',
			err.msg())
	}

	// product_variants_availability
	sales_channel_ids_bin := get_sales_channel_ids_bin(product_data.sales_channels)
	model_sales_channel_stock_location_retrieve_params := ModelSalesChannelStockLocationRetrieveParams{
		sales_channel_ids_bin: sales_channel_ids_bin
	}
	sales_channel_stock_locations := model_sales_channel_stock_location_retrieve(mut tx,
		model_sales_channel_stock_location_retrieve_params) or {
		tx.rollback() or {} // ignore error
		if err is InternalError {
			return handle_error_500(mut ctx, err.message, err.details)
		}
		return handle_error_500(mut ctx, 'Failed to retrieve sales_channel_stock_location',
			err.msg())
	}

	tx.rollback() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }

	assign_product_data(mut product_data, mut product)

	// product_variants_availability
	mut complete_product_variants := []ProductVariant{len: product_data.product_variants.len}
	for i := 0; i < product_data.product_variants.len; i++ {
		variant_id := product_data.product_variants[i].id
		complete_product_variants[i] = product_data.product_variants_map[variant_id]
	}

	product_variants_availability := get_product_variants_availability(GetProductVariantsAvailabilityParams{
		product_variants:              complete_product_variants
		sales_channel_ids_bin:         ph.sales_channel_ids_bin
		product_sales_channels:        product_data.product_sales_channels
		sales_channel_stock_locations: sales_channel_stock_locations
	})

	external_product := format_product_response_admin(product, product_variants_availability)

	return ctx.json(ProductResponseEnvelope{
		product: external_product
	})
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
		}
		return handle_error_500(mut ctx, 'Unhandled error at suite_product_data_get',
			err.msg())
	}

	// product_variants_availability
	sales_channel_ids_bin := get_sales_channel_ids_bin(product_data.sales_channels)
	model_sales_channel_stock_location_retrieve_params := ModelSalesChannelStockLocationRetrieveParams{
		sales_channel_ids_bin: sales_channel_ids_bin
	}
	sales_channel_stock_locations := model_sales_channel_stock_location_retrieve(mut tx,
		model_sales_channel_stock_location_retrieve_params) or {
		if err is InternalError {
			return handle_error_500(mut ctx, err.message, err.details)
		}
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Failed to retrieve sales_channel_stock_location',
			err.msg())
	}

	tx.rollback() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }

	assign_product_data(mut product_data, mut product)

	pctx := PriceContext{
		// cart_id_bin
		// customer_id_bin
		region_id_bin: ph.region_id_bin
	}

	mut variant_prices_map := map[string]ProductVariantPrice{}
	mut complete_product_variants := []ProductVariant{len: product_data.product_variants.len}
	for i := 0; i < product_data.product_variants.len; i++ {
		variant := product_data.product_variants[i]
		complete_product_variants[i] = product_data.product_variants_map[variant.id]
		variant_prices_map[variant.id] = calculate_price(variant, 1, pctx)
	}

	product_variants_availability := get_product_variants_availability(GetProductVariantsAvailabilityParams{
		product_variants:              complete_product_variants
		sales_channel_ids_bin:         ph.sales_channel_ids_bin
		product_sales_channels:        product_data.product_sales_channels
		sales_channel_stock_locations: sales_channel_stock_locations
	})

	external_product := format_product_response_store(product, pctx, product_variants_availability)

	return ctx.json(ProductResponseEnvelope{
		product: external_product
	})
}

fn conduit_products_update(mut app App, mut ctx Context, product_id_bin []u8, ph ProductUpdateRequestHygienised) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	if ph.handle != none || ph.is_giftcard != none || ph.status != none || ph.thumbnail != none
		|| ph.type_id != none || ph.discountable != none || ph.metadata != none {
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

	if _ := ph.collection_ids {
		// TODO
	}

	if translations := ph.translations {
		model_product_translation_update(mut tx, product_id_bin, translations) or {
			tx.rollback() or {}
			return handle_error_500(mut ctx, 'Failed to update product translations',
				err.msg())
		}
	}

	if seo_translations := ph.seo_translations {
		mut seo_translation_ids_bin := [][]u8{len: seo_translations.len}
		for i := 0; i < seo_translations.len; i++ {
			_, seo_translation_ids_bin[i] = app.new_id()
		}

		p := ProductSEOUpdateParams{
			product_id_bin:          product_id_bin
			seo_translation_ids_bin: seo_translation_ids_bin
			seo_translations:        seo_translations
		}

		model_product_seo_update(mut tx, p) or {
			tx.rollback() or {}
			return handle_error_500(mut ctx, 'Failed to update product seo translations',
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

fn conduit_product_option_list(mut app App, mut ctx Context, product_id_bin []u8) veb.Result {
	// return options and their values
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	mut product_option_data := suite_product_option_data_get(mut tx, [
		product_id_bin,
	]) or {
		tx.rollback() or {}
		if err is InternalError {
			return handle_suite_error(mut ctx, err)
		}
		return handle_error_unhandled(mut ctx, err.msg(), 'suite_product_option_data_get')
	}

	tx.rollback() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }

	product_options := product_option_data.build_product_options()

	mut external_product_options := []ProductOptionResponse{len: product_options.len}
	for i := 0; i < product_options.len; i++ {
		external_product_options[i] = format_product_option_response(product_options[i])
	}

	// TODO count, offset, fetch
	return ctx.json(ProductOptionListEnvelope{
		options: external_product_options
	})
}

fn conduit_product_option_create(mut app App, mut ctx Context, product_id string, product_id_bin []u8, ph ProductOptionCreateRequestHygienised) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	_, product_option_id_bin := app.new_id()
	mut product_option_value_ids_bin := [][]u8{len: ph.values.len}
	for i := 0; ph.values.len; i++ {
		_, product_option_value_ids_bin[i] = app.new_id()
	}

	model_product_option_create(mut tx, product_id_bin, product_option_id_bin, product_option_value_ids_bin,
		ph) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not create product_option', err.msg())
	}

	tx.commit() or { return handle_error_500(mut ctx, error_transaction_commit, err.msg()) }

	return success(mut ctx)
}

fn conduit_product_option_update(mut app App, mut ctx Context, product_id string, product_id_bin []u8, product_option_id string, product_option_id_bin []u8, ph ProductOptionUpdateRequestHygienised) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	model_product_option_update(mut tx, product_option_id_bin, ph.translations) or {
		tx.rollback() or {} // ignore error
		return handle_error_500(mut ctx, 'Could not create product_option: could not insert translations',
			err.msg())
	}

	tx.commit() or { return handle_error_500(mut ctx, error_transaction_commit, err.msg()) }

	return success(mut ctx)
}

// returns an error when attempting to delete options if more than one variant exist
// require user to delete all variants manually first, then allow deletion of any option
// TODO move these checks to route? It is input validation, right?
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
		return handle_error_500(mut ctx, 'Could not delee product_option: could not retrieve product_variant',
			err.msg())
	}

	if count > 1 {
		tx.rollback() or {} // ignore error
		return handle_error_400(mut ctx, 'Could not delete product_option: there exist more than one product_variant',
			'more than one variant exist')
	}

	model_product_option_delete(mut tx, product_option_id_bin) or {
		tx.rollback() or {} // ignore error
		return handle_error_400(mut ctx, 'Could not delete product_option', err.msg())
	}

	tx.commit() or { return handle_error_500(mut ctx, error_transaction_commit, err.msg()) }

	return success(mut ctx)
}

fn conduit_product_option_value_create(mut app App, mut ctx Context, product_option_id_bin []u8, ph ProductOptionValueRequestHygienised) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	_, product_option_value_id_bin := app.new_id()

	model_product_option_value_create(mut tx, product_option_id_bin, product_option_value_id_bin) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not create product_option_value', err.msg())
	}

	model_product_option_value_update(mut tx, product_option_value_id_bin, ph) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not insert product_option_value_translations',
			err.msg())
	}

	tx.commit() or { return handle_error_500(mut ctx, error_transaction_commit, err.msg()) }

	return success(mut ctx)
}

fn conduit_product_option_value_update(mut app App, mut ctx Context, product_option_value_id_bin []u8, ph ProductOptionValueRequestHygienised) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	model_product_option_value_update(mut tx, product_option_value_id_bin, ph) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not update product_option_value_translations',
			err.msg())
	}

	tx.commit() or { return handle_error_500(mut ctx, error_transaction_commit, err.msg()) }

	return success(mut ctx)
}

fn conduit_product_option_value_delete(mut app App, mut ctx Context, product_option_value_id_bin []u8) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	model_product_option_value_delete(mut tx, product_option_value_id_bin) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not delete product_option_value', err.msg())
	}

	tx.commit() or { return handle_error_500(mut ctx, error_transaction_commit, err.msg()) }

	return success(mut ctx)
}
