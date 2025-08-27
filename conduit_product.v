module peony

import arrays
import log
import veb

fn conduit_products_get(mut app App, mut ctx Context, ph RetrieveProductParamsHygienised) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	count := model_product_retrieve_count(mut tx, ph) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Failed to retrieve product count', err.msg())
	}

	products := model_product_retrieve(mut tx, ph) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Failed to retrieve product', err.msg())
	}

	mut product_map, product_ids_bin := make_product_map(products)
	translations := model_product_translation_retrieve(mut tx, product_ids_bin) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Failed to retrieve product_translation', err.msg())
	}

	for i := 0; i < translations.len; i++ {
		product_id := translations[i].product_id
		product_map[product_id].translations = arrays.concat(product_map[product_id].translations,
			translations[i])
	}

	product_sales_channels := model_product_sales_channel_retrieve(mut tx, product_ids_bin) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Failed to retrieve product_sales_channel', err.msg())
	}

	// Get all the sales channels, there should not be many.
	sales_channels := model_sales_channel_retrieve(mut tx, ListSalesChannelsParamsHygienised{}) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Failed to retrieve sales_channel', err.msg())
	}

	sales_channels_map, _ := make_sales_channel_map(sales_channels)
	for i := 0; i < product_sales_channels.len; i++ {
		product_id := product_sales_channels[i].product_id
		sales_channel_id := product_sales_channels[i].sales_channel_id
		sales_channel := sales_channels_map[sales_channel_id]
		old_sales_channels := product_map[product_id].sales_channels
		new_sales_channels := arrays.concat(old_sales_channels, sales_channel)
		product_map[product_id].sales_channels = new_sales_channels
	}

	mut product_variants, _ := model_product_variants_retrieve_by_product_ids(mut tx,
		product_ids_bin) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Failed to retrieve product_variant', err.msg())
	}
	mut product_variants_map, product_variant_ids_bin := make_product_variant_map(product_variants)

	if product_variants.len > 0 {
		money_amounts := model_product_variant_money_amount_retrieve(mut tx, product_variant_ids_bin) or {
			tx.rollback() or {}
			return handle_error_500(mut ctx, 'Failed to retrieve product_variant_money_amount',
				err.msg())
		}

		for i := 0; i < money_amounts.len; i++ {
			money_amount := money_amounts[i]
			variant_id := id_bin_to_string(money_amount.variant_id_bin.value) or {
				log.error('money_amount.variant_id cannot be parsed: ${err}')
				return handle_error_500(mut ctx, error_database_data_malformed, err.msg())
			}
			old_money_amounts := product_variants_map[variant_id].money_amounts
			new_money_amounts := arrays.concat(old_money_amounts, money_amount)
			product_variants_map[variant_id].money_amounts = new_money_amounts
		}

		inventory_items := model_inventory_item_retrieve(mut tx, product_variant_ids_bin) or {
			tx.rollback() or {}
			return handle_error_500(mut ctx, 'Failed to retrieve inventory_items', err.msg())
		}

		for i := 0; i < inventory_items.len; i++ {
			inventory_item := inventory_items[i]
			variant_id := inventory_item.variant_id
			product_variants_map[variant_id].inventory_item = inventory_item
		}

		// TODO variant_image
	}

	product_options := model_product_options_retrieve_by_product_ids(mut tx, product_ids_bin) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Failed to retrieve product_option', err.msg())
	}

	if product_options.len > 0 {
		mut product_options_map, product_option_ids_bin := make_product_option_map(product_options)
		product_option_translations := model_product_option_translations_retrieve(mut tx,
			product_option_ids_bin) or {
			tx.rollback() or {}
			return handle_error_500(mut ctx, 'Failed to retrieve product_option_translations',
				err.msg())
		}

		for i := 0; i < product_option_translations.len; i++ {
			translation := product_option_translations[i]
			id := translation.product_option_id
			old_translations := product_options_map[id].translations
			new_translations := arrays.concat(old_translations, translation)
			product_options_map[id].translations = new_translations
		}

		product_option_values := model_product_option_values_retrieve(mut tx, product_option_ids_bin) or {
			tx.rollback() or {}
			return handle_error_500(mut ctx, 'Failed to retrieve product_option_values',
				err.msg())
		}
		mut product_option_values_map, product_option_value_ids_bin := make_product_option_value_map(product_option_values)

		product_option_value_translations := model_product_option_value_translations_retrieve(mut tx,
			product_option_value_ids_bin) or {
			tx.rollback() or {}
			return handle_error_500(mut ctx, 'Failed to retrieve product_option_value_translations',
				err.msg())
		}

		for i := 0; i < product_option_value_translations.len; i++ {
			translation := product_option_value_translations[i]
			id := translation.product_option_value_id
			old_translations := product_option_values_map[id].translations
			new_translations := arrays.concat(old_translations, translation)
			product_option_values_map[id].translations = new_translations
		}

		// assign complete product_option_value to options and variants
		for i := 0; i < product_option_values.len; i++ {
			product_option_value := product_option_values[i]
			id := product_option_value.id
			option_id := product_option_value.option_id
			variant_id := product_option_value.variant_id
			complete_product_option_value := product_option_values_map[id]

			option_old_values := product_options_map[option_id].values
			option_new_values := arrays.concat(option_old_values, complete_product_option_value)
			product_options_map[option_id].values = option_new_values

			variant_old_values := product_variants_map[variant_id].option_values
			variant_new_values := arrays.concat(variant_old_values, complete_product_option_value)
			product_variants_map[variant_id].option_values = variant_new_values
		}

		// assign product_option to products
		for i := 0; i < product_options.len; i++ {
			option := product_options[i]
			option_id := option.id
			product_id := option.product_id
			complete_product_option := product_options_map[option_id]

			old_options := product_map[product_id].options
			new_options := arrays.concat(old_options, complete_product_option)
			product_map[product_id].options = new_options
		}
	}

	product_images := model_product_image_retrieve(mut tx, product_ids_bin) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Failed to retrieve product_image', err.msg())
	}

	for i := 0; i < product_images.len; i++ {
		product_image := product_images[i]
		product_id := product_image.product_id
		old_images := product_map[product_id].images
		new_images := arrays.concat(old_images, product_image)
		product_map[product_id].images = new_images
	}

	// new array, using original sorting order
	mut complete_products := []Product{len: products.len}
	for i := 0; i < products.len; i++ {
		id := products[i].id
		complete_products[i] = product_map[id]
	}

	tx.rollback() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }

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
		fetch:    get_fetch_amount(ph.fetch)
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

	internal_products := model_product_retrieve(mut tx, ph) or {
		tx.rollback() or {} // ignore error
		return handle_error_500(mut ctx, 'Failed to retrieve products data', err.msg())
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
			return handle_error_500(mut ctx, 'Failed to format response', err.msg())
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
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	count := model_product_retrieve_count(mut tx, ph) or {
		tx.rollback() or {} // ignore error
		return handle_error_500(mut ctx, 'Failed to retrieve products count', err.msg())
	}

	if count == 0 {
		return handle_error_404(mut ctx, 'Not found', 'No product exists with the given id')
	}

	products := model_product_retrieve(mut tx, ph) or {
		tx.rollback() or {} // ignore error
		return handle_error_500(mut ctx, 'Failed to retrieve products data', err.msg())
	}

	mut product := products[0]

	product.translations = model_product_translation_retrieve(mut tx, ph.ids_bin) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Failed to retrieve product_translation', err.msg())
	}

	tx.rollback() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }

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

	count := model_product_retrieve_count(mut tx, ph) or {
		tx.rollback() or {} // ignore error
		return handle_error_500(mut ctx, 'Failed to retrieve products count', err.msg())
	}

	if count == 0 {
		return handle_error_404(mut ctx, 'Not found', 'No product exists with the given id')
	}

	internal_products := model_product_retrieve(mut tx, ph) or {
		tx.rollback() or {} // ignore error
		return handle_error_500(mut ctx, 'Failed to retrieve products data', err.msg())
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
		tx.rollback() or {} // ignore error
		return handle_error_500(mut ctx, 'Could not create product_option', err.msg())
	}

	model_product_option_update(mut tx, product_option_id_bin, ph) or {
		tx.rollback() or {} // ignore error
		return handle_error_500(mut ctx, 'Could not create product_option: could not insert translations',
			err.msg())
	}

	internal_variants, count := model_product_variants_retrieve_by_product_ids(mut tx,
		[product_id_bin]) or {
		tx.rollback() or {} // ignore error
		return handle_error_500(mut ctx, 'Could not add product_option to product_variants: could not retrieve product_variants',
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

	_, count := model_product_variants_retrieve_by_product_ids(mut tx, [
		product_id_bin,
	]) or {
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
