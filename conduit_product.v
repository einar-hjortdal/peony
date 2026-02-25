module peony

import veb

fn conduit_product_create(mut app App, mut ctx Context, product_id string, product_id_bin []u8, handle string, ph ProductCreateRequestHygienised) ! {
	product_create_params := ProductCreateParams{
		product_id:     product_id
		product_id_bin: product_id_bin
		title:          ph.title
		subtitle:       string_value(ph.subtitle)
		description:    string_value(ph.description)
		handle:         handle
		is_giftcard:    ph.is_giftcard
		status:         ph.status
		type_id:        string_value(ph.type_id)
		type_id_bin:    ph.type_id_bin
		discountable:   ph.discountable
		metadata:       string_value(ph.metadata)
	}

	mut tx := app.start_transaction()!

	model_product_create(mut tx, product_create_params) or {
		tx.rollback() or {}
		return new_error_internal('Failed to create product', err.msg())
	}

	_, seo_id_bin := app.new_id()
	if seo := ph.seo {
		model_product_seo_create(mut tx, seo_id_bin, product_id_bin, seo) or {
			tx.rollback() or {}
			return new_error_internal('Failed to insert seo data', err.msg())
		}

		if translations := seo.translations {
			if translations.len > 0 {
				model_seo_translations_create(mut tx, seo_id_bin, translations) or {
					tx.rollback() or {}
					return new_error_internal('Failed to insert seo_translations', err.msg())
				}
			}
		}
	} else {
		model_product_seo_create_default(mut tx, seo_id_bin, product_id_bin) or {
			tx.rollback() or {}
			return new_error_internal('Failed to create seo', err.msg())
		}
	}

	store := model_store_retrieve(mut tx) or {
		tx.rollback() or {}
		return new_error_internal('Failed to retrieve store', err.msg())
	}

	// TODO potentially loop fetch if there are more than max_fetch regions (unlikely)
	regions := model_region_retrieve(mut tx, RegionRetriveParams{ fetch: max_fetch }) or {
		tx.rollback() or {}
		return new_error_internal('Failed to retrieve regions', err.msg())
	}

	if _ := ph.tag_ids {
		// TODO
	}

	if images := ph.images {
		mut images_to_create := []ProductImageCreateParams{len: images.len}
		for i := 0; i < images.len; i++ {
			image := images[i]
			id, id_bin := app.new_id()
			images_to_create[i] = ProductImageCreateParams{
				id:           id
				id_bin:       id_bin
				url:          image.url
				alt:          image.alt
				image_rank:   i32(i)
				translations: image.translations
			}
		}

		if images_to_create.len > 0 {
			model_product_images_create(mut tx, product_id_bin, images_to_create) or {
				tx.rollback() or {}
				return new_error_internal('Failed to update product thumbnail', err.msg())
			}
		}
	}

	if thumbnail := ph.thumbnail {
		model_product_thumbnail_update(mut tx, product_id_bin, thumbnail) or {
			tx.rollback() or {}
			return new_error_internal('Failed to update product thumbnail', err.msg())
		}
	} else {
		model_product_thumbnail_update(mut tx, product_id_bin, default_thumbnail) or {
			tx.rollback() or {}
			return new_error_internal('Failed to update product thumbnail', err.msg())
		}
	}

	if _ := ph.sales_channel_ids {
		model_product_sales_channel_update(mut tx, product_id_bin, ph.sales_channel_ids_bin) or {
			tx.rollback() or {}
			return new_error_internal('Failed to update product_sales_channel', err.msg())
		}
	} else {
		model_product_sales_channel_update(mut tx, product_id_bin, [
			store.default_sales_channel_id_bin,
		]) or {
			tx.rollback() or {}
			return new_error_internal('Failed to update product_sales_channel', err.msg())
		}
	}

	if _ := ph.category_ids {
		model_category_product_update(mut tx, product_id_bin, ph.category_ids_bin) or {
			tx.rollback() or {}
			return new_error_internal('Failed to update product category relation', err.msg())
		}
	}

	if translations := ph.translations {
		if translations.len > 0 {
			model_product_translations_create(mut tx, product_id_bin, translations) or {
				tx.rollback() or {}
				return new_error_internal('Failed to update product translations', err.msg())
			}
		}
	}

	mut options_to_create := []ProductOptionCreateParams{}
	mut option_values_to_create := []ProductOptionValueCreateParams{}
	mut option_index_to_value_ids := map[int][][]u8{}
	if options := ph.options {
		options_to_create = []ProductOptionCreateParams{len: options.len}
		mut n_option_values := 0
		mut n_option_translations := 0
		for i := 0; i < options.len; i++ {
			option := options[i]
			option_id, option_id_bin := app.new_id()
			options_to_create[i] = ProductOptionCreateParams{
				id:             option_id
				id_bin:         option_id_bin
				product_id:     product_id
				product_id_bin: product_id_bin
				option_rank:    i
				title:          option.title
			}

			n_option_values += option.values.len
			if translations := option.translations {
				n_option_translations += translations.len
			}
		}

		model_product_option_create(mut tx, options_to_create) or {
			tx.rollback() or {}
			return new_error_internal('Failed to create product_option', err.msg())
		}

		option_values_to_create = []ProductOptionValueCreateParams{len: n_option_values}
		mut values_added := 0
		mut n_value_translations := 0
		for i := 0; i < options.len; i++ {
			values := options[i].values
			option_id := options_to_create[i].id
			option_id_bin := options_to_create[i].id_bin
			for j := 0; j < values.len; j++ {
				value := values[j]
				value_id, value_id_bin := app.new_id()
				option_values_to_create[values_added] = ProductOptionValueCreateParams{
					id_string:     value_id
					id_bin:        value_id_bin
					option_id:     option_id
					option_id_bin: option_id_bin
					value_rank:    j
					name:          value.name
				}

				// update map of option index to value ids
				if j == 0 {
					// initialize array with correct length
					option_index_to_value_ids[i] = [][]u8{len: values.len}
				}
				option_index_to_value_ids[i][j] = value_id_bin

				values_added++
				if translations := value.translations {
					n_value_translations += translations.len
				}
			}
		}

		model_product_option_value_create(mut tx, option_values_to_create) or {
			tx.rollback() or {}
			return new_error_internal('Failed to create product_option_value', err.msg())
		}

		if n_option_translations > 0 {
			mut translations_to_create := []ProductOptionTranslationCreateParams{len: n_option_translations}
			mut translations_added := 0
			for i := 0; i < options.len; i++ {
				option := options[i]
				option_id := options_to_create[i].id
				option_id_bin := options_to_create[i].id_bin
				translations := option.translations or { continue }
				for j := 0; j < translations.len; j++ {
					translation := translations[j]
					translations_to_create[translations_added] = ProductOptionTranslationCreateParams{
						product_option_id:     option_id
						product_option_id_bin: option_id_bin
						locale_id:             translation.locale_id
						locale_id_bin:         translation.locale_id_bin
						title:                 translation.title
					}
					translations_added++
				}
			}

			model_product_option_translations_create(mut tx, translations_to_create) or {
				tx.rollback() or {}
				return new_error_internal('Failed to create product_option_translations',
					err.msg())
			}
		}

		if n_value_translations > 0 {
			mut translations_to_create := []ProductOptionValueTranslationCreateParams{len: n_value_translations}
			mut values_processed := 0
			mut translations_added := 0
			for i := 0; i < options.len; i++ {
				values := options[i].values
				for j := 0; j < values.len; j++ {
					value := values[j]
					value_id := option_values_to_create[values_processed].id_string
					value_id_bin := option_values_to_create[values_processed].id_bin
					translations := value.translations or { continue }
					for k := 0; k < translations.len; k++ {
						translation := translations[k]
						translations_to_create[translations_added] = ProductOptionValueTranslationCreateParams{
							product_option_value_id:     value_id
							product_option_value_id_bin: value_id_bin
							locale_id:                   translation.locale_id
							locale_id_bin:               translation.locale_id_bin
							name:                        translation.name
						}
						translations_added++
					}
					values_processed++
				}
			}
			model_product_option_value_translations_create(mut tx, translations_to_create) or {
				tx.rollback() or {}
				return new_error_internal('Failed to create product_option_value_translations',
					err.msg())
			}
		}
	} else {
		option_id, option_id_bin := app.new_id()
		options_to_create = [
			ProductOptionCreateParams{
				id:             option_id
				id_bin:         option_id_bin
				product_id:     product_id
				product_id_bin: product_id_bin
				option_rank:    0
				title:          option_default_title
			},
		]

		model_product_option_create(mut tx, options_to_create) or {
			tx.rollback() or {}
			return new_error_internal('Failed to create product_option', err.msg())
		}

		option_value_id, option_value_id_bin := app.new_id()
		option_values_to_create = [
			ProductOptionValueCreateParams{
				id_string:     option_value_id
				id_bin:        option_value_id_bin
				option_id:     option_id
				option_id_bin: option_id_bin
				value_rank:    0
				name:          option_value_default_name
			},
		]

		model_product_option_value_create(mut tx, option_values_to_create) or {
			tx.rollback() or {}
			return new_error_internal('Failed to create product_option_value', err.msg())
		}

		option_index_to_value_ids[0] = [][]u8{len: 1}
		option_index_to_value_ids[0][0] = option_value_id_bin
	}

	mut region_ids_bin := [][]u8{len: regions.len}
	mut money_amount_ids_bin := [][]u8{len: regions.len}
	for i := 0; i < regions.len; i++ {
		region_ids_bin[i] = regions[i].id_bin
		_, money_amount_ids_bin[i] = app.new_id()
	}

	if variants := ph.variants {
		mut variant_ids_bin := [][]u8{len: variants.len}
		mut variants_to_create := []VariantCreateParams{len: variants.len}
		mut option_value_ids_bin := [][][]u8{len: variants.len}
		mut n_money_amounts := 0
		mut inventory_items_to_create := []InventoryItemCreateParams{len: variants.len}
		for i := 0; i < variants.len; i++ {
			variant := variants[i]
			variant_id, variant_id_bin := app.new_id()
			variant_ids_bin[i] = variant_id_bin
			variants_to_create[i] = VariantCreateParams{
				product_id:     product_id
				product_id_bin: product_id_bin
				variant_id:     variant_id
				variant_id_bin: variant_id_bin
				image_id:       '' // TODO
				image_id_bin:   [] // TODO
				title:          string_value(variant.title)
				barcode:        string_value(variant.barcode)
				ean:            string_value(variant.ean)
				upc:            string_value(variant.upc)
				metadata:       string_value(variant.metadata)
				variant_rank:   i
			}

			option_values := variant.option_values or {
				if variants.len != 1 {
					tx.rollback() or {}
					return new_error_internal('Could not create variants', 'Missing option_values and more than one variant is to be created')
				}

				default_value_id_bin := option_index_to_value_ids[0][0]
				option_value_ids_bin[0][0] = default_value_id_bin
				continue
			}

			for j := 0; j < option_values.len; j++ {
				option_index := j
				values_index := option_values[j]
				value_id_bin := option_index_to_value_ids[option_index][values_index]
				if j == 0 {
					// initialize array
					option_value_ids_bin[i] = [][]u8{len: options_to_create.len}
				}
				option_value_ids_bin[i][j] = value_id_bin
			}

			if money_amounts := variant.money_amounts {
				n_money_amounts += money_amounts.len
			} else {
				n_money_amounts += regions.len
			}

			inventory_item_id, inventory_item_id_bin := app.new_id()
			if inventory_item := variant.inventory_item {
				inventory_items_to_create[i] = InventoryItemCreateParams{
					id:                inventory_item_id
					id_bin:            inventory_item_id_bin
					variant_id:        variant_id
					variant_id_bin:    variant_id_bin
					sku:               string_value(inventory_item.sku)
					origin_country:    string_value(inventory_item.origin_country)
					hs_code:           string_value(inventory_item.hs_code)
					mid_code:          string_value(inventory_item.mid_code)
					material:          string_value(inventory_item.material)
					weight:            i32_value(inventory_item.weight)
					length:            i32_value(inventory_item.length)
					height:            i32_value(inventory_item.height)
					width:             i32_value(inventory_item.width)
					requires_shipping: bool_or(inventory_item.requires_shipping, true)
					manage_inventory:  bool_or(inventory_item.manage_inventory, true)
					allow_backorder:   bool_or(inventory_item.allow_backorder, false)
				}
			} else {
				inventory_items_to_create[i] = InventoryItemCreateParams{
					id:                inventory_item_id
					id_bin:            inventory_item_id_bin
					variant_id:        variant_id
					variant_id_bin:    variant_id_bin
					requires_shipping: true
					manage_inventory:  true
					allow_backorder:   false
				}
			}
		}

		model_variant_create(mut tx, variants_to_create) or {
			tx.rollback() or {}
			return new_error_internal('Could not create variants', err.msg())
		}

		model_product_option_value_variants_update(mut tx, variant_ids_bin, option_value_ids_bin) or {
			tx.rollback() or {}
			return new_error_internal('Failed to create relations in product_option_value_product_variant',
				err.msg())
		}

		mut money_amounts_to_create := []VariantMoneyAmountUpdateParams{len: n_money_amounts}
		mut money_amounts_added := 0
		for i := 0; i < variants.len; i++ {
			variant := variants[i]
			variant_id := variants_to_create[i].variant_id
			variant_id_bin := variants_to_create[i].variant_id_bin
			money_amounts := variant.money_amounts or {
				for j := 0; j < regions.len; j++ {
					region := regions[j]
					money_amount_id, money_amount_id_bin := app.new_id()
					money_amounts_to_create[money_amounts_added] = VariantMoneyAmountUpdateParams{
						variant_id:          variant_id
						variant_id_bin:      variant_id_bin
						region_id:           region.id
						region_id_bin:       region.id_bin
						money_amount_id:     money_amount_id
						money_amount_id_bin: money_amount_id_bin
						is_original:         false
						amount:              default_money_amount
					}
					money_amounts_added++
				}
				continue
			}

			for j := 0; j < money_amounts.len; j++ {
				money_amount := money_amounts[j]
				money_amount_id, money_amount_id_bin := app.new_id()
				is_original := money_amount.is_original or { false }
				money_amounts_to_create[money_amounts_added] = VariantMoneyAmountUpdateParams{
					variant_id:          variant_id
					variant_id_bin:      variant_id_bin
					region_id:           money_amount.region_id
					region_id_bin:       money_amount.region_id_bin
					money_amount_id:     money_amount_id
					money_amount_id_bin: money_amount_id_bin
					is_original:         is_original
					amount:              money_amount.amount
				}
				money_amounts_added++
			}
		}

		model_variant_money_amount_update(mut tx, money_amounts_to_create) or {
			tx.rollback() or {}
			return new_error_internal('Failed to create variant money_amount', err.msg())
		}

		model_inventory_item_create(mut tx, inventory_items_to_create) or {
			tx.rollback() or {}
			return new_error_internal('Failed to create inventory_item', err.msg())
		}
	} else {
		variant_id, variant_id_bin := app.new_id()
		variant_to_create := VariantCreateParams{
			product_id:     product_id
			product_id_bin: product_id_bin
			variant_id:     variant_id
			variant_id_bin: variant_id_bin
			title:          variant_default_title
		}
		variants_to_create := [variant_to_create]
		model_variant_create(mut tx, variants_to_create) or {
			tx.rollback() or {}
			return new_error_internal('Could not create default variant', err.msg())
		}

		default_option_value := option_values_to_create[0]
		value_ids_bin := [default_option_value.id_bin]
		model_product_option_value_variant_update(mut tx, variant_id_bin, value_ids_bin) or {
			tx.rollback() or {}
			return new_error_internal('Could not associate new default variant to the new default option_value',
				err.msg())
		}

		mut money_amounts_to_create := []VariantMoneyAmountUpdateParams{len: regions.len}
		for i := 0; i < regions.len; i++ {
			region := regions[i]
			money_amount_id, money_amount_id_bin := app.new_id()
			money_amounts_to_create[i] = VariantMoneyAmountUpdateParams{
				variant_id:          variant_id
				variant_id_bin:      variant_id_bin
				region_id:           region.id
				region_id_bin:       region.id_bin
				money_amount_id:     money_amount_id
				money_amount_id_bin: money_amount_id_bin
				is_original:         false
				amount:              default_money_amount
			}
		}

		model_variant_money_amount_update(mut tx, money_amounts_to_create) or {
			tx.rollback() or {}
			return new_error_internal('Failed to create default variant money_amount',
				err.msg())
		}

		inventory_item_id, inventory_item_id_bin := app.new_id()
		inventory_item_to_create := InventoryItemCreateParams{
			id:                inventory_item_id
			id_bin:            inventory_item_id_bin
			variant_id:        variant_id
			variant_id_bin:    variant_id_bin
			requires_shipping: true
			manage_inventory:  true
			allow_backorder:   false
		}
		inventory_items_to_create := [inventory_item_to_create]
		model_inventory_item_create(mut tx, inventory_items_to_create) or {
			tx.rollback() or {}
			return new_error_internal('Failed to create default inventory_item', err.msg())
		}
	}

	// model_product_variant_money_amount_create_default(mut tx, ma_p) or {
	// 	tx.rollback() or {}
	// 	return new_error_internal('Failed to create default money_amount', err.msg())
	// 	return ctx.handle_error(perr)
	// }

	tx.commit() or { return new_error_internal(error_transaction_commit, err.msg()) }
}

fn conduit_products_list(mut app App, mut ctx Context, ph RetrieveProductParamsHygienised) veb.Result {
	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	count := model_product_retrieve_count(mut tx, ph) or {
		tx.rollback() or {}
		perr := new_error_internal('Failed to retrieve product count', err.msg())
		return ctx.handle_error(perr)
	}

	offset := get_offset_amount(ph.offset)

	if count == 0 || offset >= count {
		tx.rollback() or {
			perr := new_error_internal(error_transaction_rollback, err.msg())
			return ctx.handle_error(perr)
		}
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
		perr := new_error_internal('Failed to retrieve product', err.msg())
		return ctx.handle_error(perr)
	}

	mut products_map, product_ids_bin := make_product_map(products)
	mut products_data := suite_product_data_get(mut tx, product_ids_bin) or {
		tx.rollback() or {}
		return ctx.handle_error(err)
	}

	tx.rollback() or {
		perr := new_error_internal(error_transaction_rollback, err.msg())
		return ctx.handle_error(perr)
	}

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
	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	count := model_product_retrieve_count(mut tx, ph) or {
		tx.rollback() or {}
		perr := new_error_internal('Failed to retrieve products count', err.msg())
		return ctx.handle_error(perr)
	}

	offset := get_offset_amount(ph.offset)

	if count == 0 || offset >= count {
		tx.rollback() or {
			perr := new_error_internal(error_transaction_rollback, err.msg())
			return ctx.handle_error(perr)
		}
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
		perr := new_error_internal('Failed to retrieve product', err.msg())
		return ctx.handle_error(perr)
	}

	mut products_map, product_ids_bin := make_product_map(products)
	mut products_data := suite_product_data_get(mut tx, product_ids_bin) or {
		tx.rollback() or {}
		return ctx.handle_error(err)
	}

	// product_variants_availability
	// TODO use sales_channel id from request context created in the route handler
	// For now just use default sales_channel.id_bin
	store := model_store_retrieve(mut tx) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not retrieve store', err.msg())
		return ctx.handle_error(perr)
	}
	model_sales_channel_stock_location_retrieve_params := ModelSalesChannelStockLocationRetrieveParams{
		sales_channel_ids_bin: [store.default_sales_channel_id_bin]
	}
	sales_channel_stock_locations := model_sales_channel_stock_location_retrieve(mut tx,
		model_sales_channel_stock_location_retrieve_params) or {
		tx.rollback() or {}
		perr := new_error_internal('Failed to retrieve sales_channel_stock_location',
			err.msg())
		return ctx.handle_error(perr)
	}

	tx.rollback() or {
		perr := new_error_internal(error_transaction_rollback, err.msg())
		return ctx.handle_error(perr)
	}

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
	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	products := model_product_retrieve(mut tx, ph) or {
		tx.rollback() or {}
		perr := new_error_internal('Failed to retrieve products data', err.msg())
		return ctx.handle_error(perr)
	}

	if products.len == 0 {
		tx.rollback() or {}
		perr := new_error_not_found('No product exists with the given id', 'products.len == 0')
		return ctx.handle_error(perr)
	}

	mut product := products[0]
	mut product_data := suite_product_data_get(mut tx, [product.id_bin]) or {
		tx.rollback() or {}
		return ctx.handle_error(err)
	}

	tx.rollback() or {
		perr := new_error_internal(error_transaction_rollback, err.msg())
		return ctx.handle_error(perr)
	}

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
	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	products := model_product_retrieve(mut tx, ph) or {
		tx.rollback() or {}
		perr := new_error_internal('Failed to retrieve products data', err.msg())
		return ctx.handle_error(perr)
	}

	if products.len == 0 {
		perr := new_error_not_found('No product exists with the given id', 'products.len == 0')
		return ctx.handle_error(perr)
	}

	mut product := products[0]
	mut product_data := suite_product_data_get(mut tx, [product.id_bin]) or {
		tx.rollback() or {}
		return ctx.handle_error(err)
	}

	// product_variants_availability
	// TODO use sales_channel id from request context created in the route handler
	// For now just use default sales_channel.id_bin
	store := model_store_retrieve(mut tx) or {
		tx.rollback() or {}
		perr := new_error_internal('could not retrieve store', err.msg())
		return ctx.handle_error(perr)
	}
	model_sales_channel_stock_location_retrieve_params := ModelSalesChannelStockLocationRetrieveParams{
		sales_channel_ids_bin: [store.default_sales_channel_id_bin]
	}
	sales_channel_stock_locations := model_sales_channel_stock_location_retrieve(mut tx,
		model_sales_channel_stock_location_retrieve_params) or {
		tx.rollback() or {}
		perr := new_error_internal('Failed to retrieve sales_channel_stock_location',
			err.msg())
		return ctx.handle_error(perr)
	}

	tx.rollback() or {
		perr := new_error_internal(error_transaction_rollback, err.msg())
		return ctx.handle_error(perr)
	}

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
	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	model_product_update(mut tx, p) or {
		tx.rollback() or {}
		perr := new_error_internal('Failed to update product', err.msg())
		return ctx.handle_error(perr)
	}

	if _ := ph.tag_ids {
		// TODO
	}

	if _ := ph.images {
		model_product_thumbnail_delete(mut tx, product_id_bin) or {
			tx.rollback() or {}
			perr := new_error_internal('Failed to delete product thumbnail', err.msg())
			return ctx.handle_error(perr)
		}

		if images_diff.len == 0 {
			model_product_images_delete(mut tx, product_id_bin) or {
				tx.rollback() or {}
				perr := new_error_internal('Failed to delete product images', err.msg())
				return ctx.handle_error(perr)
			}
		} else {
			model_product_images_update(mut tx, product_id_bin, images_diff) or {
				tx.rollback() or {}
				perr := new_error_internal('Failed to update product images', err.msg())
				return ctx.handle_error(perr)
			}

			if ph.thumbnail == none {
				model_product_thumbnail_update(mut tx, product_id_bin, default_thumbnail) or {
					tx.rollback() or {}
					perr := new_error_internal('Failed to update product thumbnail', err.msg())
					return ctx.handle_error(perr)
				}
			}
		}
	}

	if thumbnail := ph.thumbnail {
		model_product_thumbnail_update(mut tx, product_id_bin, thumbnail) or {
			tx.rollback() or {}
			perr := new_error_internal('Failed to update product thumbnail', err.msg())
			return ctx.handle_error(perr)
		}
	}

	if _ := ph.sales_channel_ids {
		model_product_sales_channel_update(mut tx, product_id_bin, ph.sales_channel_ids_bin) or {
			tx.rollback() or {}
			perr := new_error_internal('Failed to update product sales channel', err.msg())
			return ctx.handle_error(perr)
		}
	}

	if _ := ph.category_ids {
		model_category_product_update(mut tx, product_id_bin, ph.category_ids_bin) or {
			tx.rollback() or {}
			perr := new_error_internal('Failed to update product category relation', err.msg())
			return ctx.handle_error(perr)
		}
	}

	if translations := ph.translations {
		model_product_translations_delete(mut tx, product_id_bin) or {
			tx.rollback() or {}
			perr := new_error_internal('Failed to delete from product_translations', err.msg())
			return ctx.handle_error(perr)
		}

		if translations.len > 0 {
			model_product_translations_create(mut tx, product_id_bin, translations) or {
				tx.rollback() or {}
				perr := new_error_internal('Failed to create product_translations', err.msg())
				return ctx.handle_error(perr)
			}
		}
	}

	if seo := ph.seo {
		if seo.title != none || seo.description != none {
			model_seo_update(mut tx, seo_id_bin, seo) or {
				tx.rollback() or {}
				perr := new_error_internal('Could not update seo', err.msg())
				return ctx.handle_error(perr)
			}
		}

		if translations := seo.translations {
			model_seo_translations_delete(mut tx, seo_id_bin) or {
				tx.rollback() or {}
				perr := new_error_internal('Could not delete seo_translations', err.msg())
				return ctx.handle_error(perr)
			}

			if translations.len > 0 {
				model_seo_translations_create(mut tx, seo_id_bin, translations) or {
					tx.rollback() or {}
					perr := new_error_internal('Could not update seo_translations', err.msg())
					return ctx.handle_error(perr)
				}
			}
		}
	}

	tx.commit() or {
		perr := new_error_internal(error_transaction_commit, err.msg())
		return ctx.handle_error(perr)
	}

	return success(mut ctx)
}

fn conduit_product_delete(mut app App, mut ctx Context, product_id_bin []u8) veb.Result {
	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	model_product_delete(mut tx, product_id_bin) or {
		tx.rollback() or {}
		perr := new_error_internal('Failed to delete product', err.msg())
		return ctx.handle_error(perr)
	}

	tx.commit() or {
		perr := new_error_internal(error_transaction_commit, err.msg())
		return ctx.handle_error(perr)
	}

	return success(mut ctx)
}
