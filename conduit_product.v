module peony

import veb

fn conduit_product_create(mut app App, mut ctx Context, p ProductCreateParams, images_to_create []ProductImageCreateParams, ph ProductCreateRequestHygienised) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	model_product_create(mut tx, p) or {
		tx.rollback() or {} // ignore error
		return handle_error_500(mut ctx, 'Failed to create product', err.msg())
	}

	_, seo_id_bin := app.new_id()
	if seo := ph.seo {
		model_product_seo_create(mut tx, seo_id_bin, p.product_id_bin, seo) or {
			tx.rollback() or {} // ignore error
			return handle_error_500(mut ctx, 'Failed to insert seo data', err.msg())
		}

		if translations := seo.translations {
			if translations.len > 0 {
				model_seo_translations_create(mut tx, seo_id_bin, translations) or {
					tx.rollback() or {}
					return handle_error_500(mut ctx, 'Failed to insert seo_translations',
						err.msg())
				}
			}
		}
	} else {
		model_product_seo_create_default(mut tx, seo_id_bin, p.product_id_bin) or {
			tx.rollback() or {} // ignore error
			return handle_error_500(mut ctx, 'Failed to create seo', err.msg())
		}
	}

	store := model_store_retrieve(mut tx) or {
		tx.rollback() or {} // ignore error
		return handle_error_500(mut ctx, 'Failed to retrieve store', err.msg())
	}

	// TODO potentially loop fetch if there are more than max_fetch regions (unlikely)
	regions := model_region_retrieve(mut tx, RegionRetriveParams{ fetch: max_fetch }) or {
		tx.rollback() or {} // ignore error
		return handle_error_500(mut ctx, 'Failed to retrieve regions', err.msg())
	}

	if _ := ph.tag_ids {
		// TODO
	}

	if images_to_create.len > 0 {
		model_product_images_create(mut tx, p.product_id_bin, images_to_create) or {
			tx.rollback() or {}
			return handle_error_500(mut ctx, 'Failed to create product images', err.msg())
		}
	}

	if thumbnail := ph.thumbnail {
		model_product_thumbnail_update(mut tx, p.product_id_bin, thumbnail) or {
			tx.rollback() or {}
			return handle_error_500(mut ctx, 'Failed to update product thumbnail', err.msg())
		}
	} else {
		model_product_thumbnail_update(mut tx, p.product_id_bin, default_thumbnail) or {
			tx.rollback() or {}
			return handle_error_500(mut ctx, 'Failed to update product thumbnail', err.msg())
		}
	}

	if _ := ph.sales_channel_ids {
		model_product_sales_channel_update(mut tx, p.product_id_bin, ph.sales_channel_ids_bin) or {
			tx.rollback() or {}
			return handle_error_500(mut ctx, 'Failed to update product_sales_channel',
				err.msg())
		}
	} else {
		model_product_sales_channel_update(mut tx, p.product_id_bin, [
			store.default_sales_channel_id_bin,
		]) or {
			tx.rollback() or {}
			return handle_error_500(mut ctx, 'Failed to update product_sales_channel',
				err.msg())
		}
	}

	if _ := ph.category_ids {
		model_category_product_update(mut tx, p.product_id_bin, ph.category_ids_bin) or {
			tx.rollback() or {}
			return handle_error_500(mut ctx, 'Failed to update product category relation',
				err.msg())
		}
	}

	if translations := ph.translations {
		if translations.len > 0 {
			model_product_translations_create(mut tx, p.product_id_bin, translations) or {
				tx.rollback() or {}
				return handle_error_500(mut ctx, 'Failed to update product translations',
					err.msg())
			}
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
		model_variant_create_default_with_options(mut app, mut tx, p.product_id_bin, variant_id_bin,
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
			product_id_bin:        p.product_id_bin
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

fn conduit_products_list(mut app App, mut ctx Context, ph RetrieveProductParamsHygienised) veb.Result {
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
		if err is PeonyError {
			return ctx.handle_peony_error(err)
		}
		return ctx.handle_unhandled_error('Unhandled error at suite_product_data_get',
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

	mut external_products := []ProductResponse{len: complete_products.len}
	for i := 0; i < complete_products.len; i++ {
		external_products[i] = format_product_response(complete_products[i])
	}

	return ctx.json(ProductResponseListEnvelope{
		products: external_products
		count:    count
		offset:   get_offset_amount(ph.offset)
		fetch:    ph.fetch.v
	})
}

fn conduit_products_list_store(mut app App, mut ctx Context, ph RetrieveProductParamsHygienised) veb.Result {
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
		if err is PeonyError {
			return ctx.handle_peony_error(err)
		}
		return ctx.handle_unhandled_error('Unhandled error at suite_product_data_get',
			err.msg())
	}

	// product_variants_availability
	// TODO use sales_channel id from request context created in the route handler
	// For now just use default sales_channel.id_bin
	store := model_store_retrieve(mut tx) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'could not retrieve store', err.msg())
	}
	model_sales_channel_stock_location_retrieve_params := ModelSalesChannelStockLocationRetrieveParams{
		sales_channel_ids_bin: [store.default_sales_channel_id_bin]
	}
	sales_channel_stock_locations := model_sales_channel_stock_location_retrieve(mut tx,
		model_sales_channel_stock_location_retrieve_params) or {
		tx.rollback() or {}
		if err is PeonyError {
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
	mut variant_prices_map := map[string]VariantPrice{}
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

	mut external_products := []ProductResponseStore{len: complete_products.len}
	for i := 0; i < complete_products.len; i++ {
		external_products[i] = format_product_response_store(complete_products[i], pctx,
			product_variants_availability, ph.locale_id.v)
	}

	return ctx.json(ProductResponseStoreListEnvelope{
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
		perr := new_error_not_found('No product exists with the given id', 'products.len == 0')
		return ctx.handle_peony_error(perr)
	}

	mut product := products[0]
	mut product_data := suite_product_data_get(mut tx, [product.id_bin]) or {
		tx.rollback() or {}
		if err is PeonyError {
			return ctx.handle_peony_error(err)
		}
		return ctx.handle_unhandled_error('Unhandled error at suite_product_data_get',
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

	external_product := format_product_response(product)

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
		perr := new_error_not_found('No product exists with the given id', 'products.len == 0')
		return ctx.handle_peony_error(perr)
	}

	mut product := products[0]
	mut product_data := suite_product_data_get(mut tx, [product.id_bin]) or {
		tx.rollback() or {}
		if err is PeonyError {
			return ctx.handle_peony_error(err)
		}
		return ctx.handle_unhandled_error('Unhandled error at suite_product_data_get',
			err.msg())
	}

	// product_variants_availability
	// TODO use sales_channel id from request context created in the route handler
	// For now just use default sales_channel.id_bin
	store := model_store_retrieve(mut tx) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'could not retrieve store', err.msg())
	}
	model_sales_channel_stock_location_retrieve_params := ModelSalesChannelStockLocationRetrieveParams{
		sales_channel_ids_bin: [store.default_sales_channel_id_bin]
	}
	sales_channel_stock_locations := model_sales_channel_stock_location_retrieve(mut tx,
		model_sales_channel_stock_location_retrieve_params) or {
		if err is PeonyError {
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

	mut variant_prices_map := map[string]VariantPrice{}
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

	external_product := format_product_response_store(product, pctx, product_variants_availability,
		ph.locale_id.v)

	return ctx.json(ProductResponseStoreEnvelope{
		product: external_product
	})
}

// TODO handle options
// TODO handle variants
fn conduit_product_update(mut app App, mut ctx Context, product_id_bin []u8, seo_id_bin []u8, images_diff []ProductImageUpdateParams, p ProductUpdateParams, ph ProductUpdateRequestHygienised) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	model_product_update(mut tx, p) or {
		tx.rollback() or {} // ignore error
		return handle_error_500(mut ctx, 'Failed to update product', err.msg())
	}

	if _ := ph.tag_ids {
		// TODO
	}

	if _ := ph.images {
		model_product_thumbnail_delete(mut tx, product_id_bin) or {
			tx.rollback() or {}
			return handle_error_500(mut ctx, 'Failed to delete product thumbnail', err.msg())
		}

		if images_diff.len == 0 {
			model_product_images_delete(mut tx, product_id_bin) or {
				tx.rollback() or {}
				return handle_error_500(mut ctx, 'Failed to delete product images', err.msg())
			}
		} else {
			model_product_images_update(mut tx, product_id_bin, images_diff) or {
				tx.rollback() or {}
				return handle_error_500(mut ctx, 'Failed to update product images', err.msg())
			}

			if ph.thumbnail == none {
				model_product_thumbnail_update(mut tx, product_id_bin, default_thumbnail) or {
					tx.rollback() or {}
					return handle_error_500(mut ctx, 'Failed to update product thumbnail',
						err.msg())
				}
			}
		}
	}

	if thumbnail := ph.thumbnail {
		model_product_thumbnail_update(mut tx, product_id_bin, thumbnail) or {
			tx.rollback() or {}
			return handle_error_500(mut ctx, 'Failed to update product thumbnail', err.msg())
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
		model_category_product_update(mut tx, product_id_bin, ph.category_ids_bin) or {
			tx.rollback() or {}
			return handle_error_500(mut ctx, 'Failed to update product category relation',
				err.msg())
		}
	}

	if translations := ph.translations {
		model_product_translations_delete(mut tx, product_id_bin) or {
			tx.rollback() or {}
			return handle_error_500(mut ctx, 'Failed to delete from product_translations',
				err.msg())
		}

		if translations.len > 0 {
			model_product_translations_create(mut tx, product_id_bin, translations) or {
				tx.rollback() or {}
				return handle_error_500(mut ctx, 'Failed to create product_translations',
					err.msg())
			}
		}
	}

	if seo := ph.seo {
		if seo.title != none || seo.description != none {
			model_seo_update(mut tx, seo_id_bin, seo) or {
				tx.rollback() or {}
				return handle_error_500(mut ctx, 'Could not update seo', err.msg())
			}
		}

		if translations := seo.translations {
			model_seo_translations_delete(mut tx, seo_id_bin) or {
				tx.rollback() or {}
				return handle_error_500(mut ctx, 'Could not delete seo_translations',
					err.msg())
			}

			if translations.len > 0 {
				model_seo_translations_create(mut tx, seo_id_bin, translations) or {
					tx.rollback() or {}
					return handle_error_500(mut ctx, 'Could not update seo_translations',
						err.msg())
				}
			}
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
