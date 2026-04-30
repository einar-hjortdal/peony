module peony

import arrays
import veb
import einar_hjortdal.firebird
import record

pub type Product = record.Product

pub type ProductCreateParams = record.ProductCreateParams

pub struct ProductCreateData {
	product ProductCreateParams
	seo ProductSEOCreateParams
	seo_translations ?SEOTranslation
}

fn product_create(mut tx firebird.Transaction, product_id ID, handle string, p ProductCreateData) ! {
	record.product_create(mut tx, p.product) or { return new_error_internal('Failed to create product', err.msg()) }

		record.product_seo_create(mut tx, seo) or {
			return new_error_internal('Failed to insert seo data', err.msg())
		}

		if translations := seo.translations {
			if translations.len > 0 {
				record.seo_translations_create(mut tx, translations) or {
					return new_error_internal('Failed to insert seo_translations', err.msg())
				}
			}
		}

	store := record.store_retrieve(mut tx) or {
		return new_error_internal('Failed to retrieve store', err.msg())
	}

	// TODO loop or fix firebird lib
	regions := record.region_retrieve(mut tx, RegionRetriveParams{
		fetch: max_fetch
		order: order_default
	}) or { return new_error_internal('Failed to retrieve regions', err.msg()) }

	// images array is kept at the top level so that it can be used later with variant images
	mut images_to_create := []ProductImageCreateParams{}
	if images := ph.images {
		images_to_create = []ProductImageCreateParams{len: images.len}
		for i := 0; i < images.len; i++ {
			image := images[i]
			id := app.gen_id()
			images_to_create[i] = ProductImageCreateParams{
				id:           id
				url:          image.url
				alt:          image.alt
				image_rank:   i
				translations: image.translations
			}
		}

		if images_to_create.len > 0 {
			record.product_images_create(mut tx, product_id, images_to_create) or {
				return new_error_internal('Failed to create product_image', err.msg())
			}
		}
	}

	if thumbnail := ph.thumbnail {
		record.product_thumbnail_update(mut tx, product_id, thumbnail) or {
			return new_error_internal('Failed to update product thumbnail', err.msg())
		}
	} else {
		record.product_thumbnail_update(mut tx, product_id, default_thumbnail) or {
			return new_error_internal('Failed to update product thumbnail', err.msg())
		}
	}

	if sales_channel_ids := ph.sales_channel_ids {
		record.product_sales_channel_update(mut tx, product_id, sales_channel_ids) or {
			return new_error_internal('Failed to update product_sales_channel', err.msg())
		}
	} else {
		record.product_sales_channel_update(mut tx, product_id, [
			store.default_sales_channel_id,
		]) or { return new_error_internal('Failed to update product_sales_channel', err.msg()) }
	}

	if category_ids := ph.category_ids {
		record.category_product_update(mut tx, product_id, category_ids) or {
			return new_error_internal('Failed to update product category relation', err.msg())
		}
	}

	if translations := ph.translations {
		if translations.len > 0 {
			record.product_translations_create(mut tx, product_id, translations) or {
				return new_error_internal('Failed to update product translations', err.msg())
			}
		}
	}

	mut options_to_create := []ProductOptionCreateParams{}
	mut option_values_to_create := []ProductOptionValueCreateParams{}
	mut option_index_to_value_ids := map[int][]ID{}
	if options := ph.options {
		options_to_create = []ProductOptionCreateParams{len: options.len}
		mut n_option_values := 0
		mut n_option_translations := 0
		for i := 0; i < options.len; i++ {
			option := options[i]
			option_id := app.gen_id()
			options_to_create[i] = ProductOptionCreateParams{
				id:          option_id
				product_id:  product_id
				option_rank: i
				title:       option.title
			}

			n_option_values += option.values.len
			if translations := option.translations {
				n_option_translations += translations.len
			}
		}

		record.product_option_create(mut tx, options_to_create) or {
			return new_error_internal('Failed to create product_option', err.msg())
		}

		option_values_to_create = []ProductOptionValueCreateParams{len: n_option_values}
		mut values_added := 0
		mut n_value_translations := 0
		for i := 0; i < options.len; i++ {
			values := options[i].values
			option_id := options_to_create[i].id
			for j := 0; j < values.len; j++ {
				value := values[j]
				value_id := app.gen_id()
				option_values_to_create[values_added] = ProductOptionValueCreateParams{
					id:         value_id
					option_id:  option_id
					value_rank: j
					name:       value.name
				}

				// update map of option index to value ids
				if j == 0 {
					// initialize array with correct length
					option_index_to_value_ids[i] = []ID{len: values.len}
				}
				option_index_to_value_ids[i][j] = value_id

				values_added++
				if translations := value.translations {
					n_value_translations += translations.len
				}
			}
		}

		record.product_option_value_create(mut tx, option_values_to_create) or {
			return new_error_internal('Failed to create product_option_value', err.msg())
		}

		if n_option_translations > 0 {
			mut translations_to_create := []ProductOptionTranslationParams{len: n_option_translations}
			mut translations_added := 0
			for i := 0; i < options.len; i++ {
				option := options[i]
				option_id := options_to_create[i].id
				translations := option.translations or { continue }
				for j := 0; j < translations.len; j++ {
					translation := translations[j]
					translations_to_create[translations_added] = ProductOptionTranslationParams{
						product_option_id: option_id
						locale_id:         translation.locale_id
						title:             translation.title
					}
					translations_added++
				}
			}

			record.product_option_translations_create(mut tx, translations_to_create) or {
				return new_error_internal('Failed to create product_option_translations', err.msg())
			}
		}

		if n_value_translations > 0 {
			mut translations_to_create := []ProductOptionValueTranslationParams{len: n_value_translations}
			mut values_processed := 0
			mut translations_added := 0
			for i := 0; i < options.len; i++ {
				values := options[i].values
				for j := 0; j < values.len; j++ {
					value := values[j]
					value_id := option_values_to_create[values_processed].id
					translations := value.translations or { continue }
					for k := 0; k < translations.len; k++ {
						translation := translations[k]
						translations_to_create[translations_added] = ProductOptionValueTranslationParams{
							product_option_value_id: value_id
							locale_id:               translation.locale_id
							name:                    translation.name
						}
						translations_added++
					}
					values_processed++
				}
			}
			record.product_option_value_translations_create(mut tx, translations_to_create) or {
				return new_error_internal('Failed to create product_option_value_translations',
					err.msg())
			}
		}
	} else {
		option_id := app.gen_id()
		options_to_create = [
			ProductOptionCreateParams{
				id:          option_id
				product_id:  product_id
				option_rank: 0
				title:       option_default_title
			},
		]

		record.product_option_create(mut tx, options_to_create) or {
			return new_error_internal('Failed to create product_option', err.msg())
		}

		option_value_id := app.gen_id()
		option_values_to_create = [
			ProductOptionValueCreateParams{
				id:         option_value_id
				option_id:  option_id
				value_rank: 0
				name:       option_value_default_name
			},
		]

		record.product_option_value_create(mut tx, option_values_to_create) or {
			return new_error_internal('Failed to create product_option_value', err.msg())
		}

		option_index_to_value_ids[0] = [option_value_id]
	}

	mut region_ids := []ID{len: regions.len}
	mut money_amount_ids := []ID{len: regions.len}
	for i := 0; i < regions.len; i++ {
		region_ids[i] = regions[i].id
		money_amount_ids[i] = app.gen_id()
	}

	if variants := ph.variants {
		mut variant_ids := []ID{len: variants.len}
		mut variants_to_create := []VariantCreateParams{len: variants.len}
		mut inventory_items_to_create := []InventoryItemCreateParams{len: variants.len}
		for i := 0; i < variants.len; i++ {
			variant := variants[i]
			variant_id := app.gen_id()
			variant_ids[i] = variant_id

			mut image_id := ?ID(none)
			if image := variant.image {
				image_id = images_to_create[image].id
			}

			variants_to_create[i] = VariantCreateParams{
				product_id:   product_id
				variant_id:   variant_id
				image_id:     image_id
				title:        string_value(variant.title)
				barcode:      string_value(variant.barcode)
				ean:          string_value(variant.ean)
				upc:          string_value(variant.upc)
				metadata:     string_value(variant.metadata)
				variant_rank: i
			}

			inventory_item_id := app.gen_id()
			if inventory_item := variant.inventory_item {
				inventory_items_to_create[i] = InventoryItemCreateParams{
					id:                inventory_item_id
					variant_id:        variant_id
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
					variant_id:        variant_id
					requires_shipping: true
					manage_inventory:  true
					allow_backorder:   false
				}
			}
		}

		record.variant_create(mut tx, variants_to_create) or {
			return new_error_internal('Could not create variants', err.msg())
		}

		// product_option_value_variant
		mut n_relations := 1 // if no option_values defined, one default option_value
		if option_values := variants[0].option_values {
			n_relations = option_values.len * variants.len // all variants must reference all options
		}
		mut relations := []ProductOptionValueProductVariant{len: n_relations}
		mut relations_created := 0
		for i := 0; i < variants.len; i++ {
			variant := variants[i]
			variant_id := variants_to_create[i].variant_id
			option_values := variant.option_values or {
				if variants.len != 1 && n_relations != 1 {
					return new_error_internal('Could not create product_option_value_variant',
						'Missing option_values and more than one variant is to be created')
				}

				value_id := option_index_to_value_ids[0][0] // default
				relations[0] = ProductOptionValueProductVariant{
					option_value_id: value_id
					variant_id:      variant_id
				}

				break
			}

			for j := 0; j < option_values.len; j++ {
				option_index := j
				value_index := option_values[j]
				value_id := option_index_to_value_ids[option_index][value_index]
				relations[relations_created] = ProductOptionValueProductVariant{
					option_value_id: value_id
					variant_id:      variant_id
				}
				relations_created++
			}
		}

		record.product_option_value_variant_update(mut tx, ProductOptionValueProductVariantParams{
			variant_ids: variant_ids
			relations:   relations
		}) or {
			return new_error_internal('Failed to create relations in product_option_value_variant',
				err.msg())
		}

		mut n_money_amounts := 0
		for i := 0; i < variants.len; i++ {
			variant := variants[i]
			if money_amounts := variant.money_amounts {
				n_money_amounts += money_amounts.len
				continue
			}
			n_money_amounts += regions.len
		}

		mut money_amounts_to_create := []VariantMoneyAmountUpdateParams{len: n_money_amounts}
		mut money_amounts_added := 0
		for i := 0; i < variants.len; i++ {
			variant := variants[i]
			variant_id := variants_to_create[i].variant_id
			money_amounts := variant.money_amounts or {
				for j := 0; j < regions.len; j++ {
					region := regions[j]
					money_amount_id := app.gen_id()
					money_amounts_to_create[money_amounts_added] = VariantMoneyAmountUpdateParams{
						variant_id:      variant_id
						region_id:       region.id
						money_amount_id: money_amount_id
						is_original:     false
						amount:          default_money_amount
					}
					money_amounts_added++
				}
				continue
			}

			for j := 0; j < money_amounts.len; j++ {
				money_amount := money_amounts[j]
				money_amount_id := app.gen_id()
				money_amounts_to_create[money_amounts_added] = VariantMoneyAmountUpdateParams{
					variant_id:      variant_id
					region_id:       money_amount.region_id
					money_amount_id: money_amount_id
					is_original:     money_amount.is_original
					amount:          money_amount.amount
				}
				money_amounts_added++
			}
		}

		record.variant_money_amount_update(mut tx, money_amounts_to_create) or {
			return new_error_internal('Failed to create variant money_amount', err.msg())
		}

		record.inventory_item_create(mut tx, inventory_items_to_create) or {
			return new_error_internal('Failed to create inventory_item', err.msg())
		}
	} else {
		variant_id := app.gen_id()
		variant_to_create := VariantCreateParams{
			product_id: product_id
			variant_id: variant_id
			title:      variant_default_title
		}
		variants_to_create := [variant_to_create]
		record.variant_create(mut tx, variants_to_create) or {
			return new_error_internal('Could not create default variant', err.msg())
		}

		default_option_value := option_values_to_create[0]
		record.product_option_value_variant_update(mut tx, ProductOptionValueProductVariantParams{
			variant_ids: [variant_id]
			relations:   [
				ProductOptionValueProductVariant{
					variant_id:      variant_id
					option_value_id: default_option_value.id
				},
			]
		}) or {
			return new_error_internal('Could not associate new default variant to the new default option_value',
				err.msg())
		}

		mut money_amounts_to_create := []VariantMoneyAmountUpdateParams{len: regions.len}
		for i := 0; i < regions.len; i++ {
			region := regions[i]
			money_amount_id := app.gen_id()
			money_amounts_to_create[i] = VariantMoneyAmountUpdateParams{
				variant_id:      variant_id
				region_id:       region.id
				money_amount_id: money_amount_id
				is_original:     false
				amount:          default_money_amount
			}
		}

		record.variant_money_amount_update(mut tx, money_amounts_to_create) or {
			return new_error_internal('Failed to create default variant money_amount', err.msg())
		}

		inventory_item_id := app.gen_id()
		inventory_item_to_create := InventoryItemCreateParams{
			id:                inventory_item_id
			variant_id:        variant_id
			requires_shipping: true
			manage_inventory:  true
			allow_backorder:   false
		}
		inventory_items_to_create := [inventory_item_to_create]
		record.inventory_item_create(mut tx, inventory_items_to_create) or {
			return new_error_internal('Failed to create default inventory_item', err.msg())
		}
	}
}

fn conduit_product_list(mut app App, mut ctx Context, p ProductRetrieveParams) veb.Result {
	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	count := record.product_retrieve_count(mut tx, p) or {
		tx.rollback() or {}
		perr := new_error_internal('Failed to retrieve product count', err.msg())
		return ctx.handle_error(perr)
	}

	if count == 0 {
		tx.rollback() or {}
		r := ProductResponseListEnvelope{
			products: []ProductResponse{}
			count:    count
			offset:   p.offset
			fetch:    p.fetch
		}

		return ctx.json(r)
	}

	products := record.product_retrieve(mut tx, p) or {
		tx.rollback() or {}
		perr := new_error_internal('Failed to retrieve product', err.msg())
		return ctx.handle_error(perr)
	}

	mut products_map, product_ids := make_identifiable_map(products)
	mut products_data := suite_product_data_get(mut tx, product_ids) or {
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
		complete_products[i] = products_map[id.string()]
	}

	mut external_products := []ProductResponse{len: complete_products.len}
	for i := 0; i < complete_products.len; i++ {
		external_products[i] = format_product_response(complete_products[i])
	}

	return ctx.json(ProductResponseListEnvelope{
		products: external_products
		count:    count
		offset:   p.offset
		fetch:    p.fetch
	})
}

fn conduit_products_list_store(mut app App, mut ctx Context, p ProductRetrieveParams, sales_channel_id ID, price_context PriceContext, locale_context LocaleContext) veb.Result {
	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	count := record.product_retrieve_count(mut tx, p) or {
		tx.rollback() or {}
		perr := new_error_internal('Failed to retrieve products count', err.msg())
		return ctx.handle_error(perr)
	}

	if count == 0 {
		tx.rollback() or {
			perr := new_error_internal(error_transaction_rollback, err.msg())
			return ctx.handle_error(perr)
		}
		r := ProductResponseListEnvelope{
			products: []ProductResponse{}
			count:    count
			offset:   p.offset
			fetch:    p.fetch
		}

		return ctx.json(r)
	}

	products := record.product_retrieve(mut tx, p) or {
		tx.rollback() or {}
		perr := new_error_internal('Failed to retrieve product', err.msg())
		return ctx.handle_error(perr)
	}

	mut products_map, product_ids := make_identifiable_map(products)
	mut products_data := suite_product_data_get(mut tx, product_ids) or {
		tx.rollback() or {}
		return ctx.handle_error(err)
	}

	// variants_availability
	store := record.store_retrieve(mut tx) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not retrieve store', err.msg())
		return ctx.handle_error(perr)
	}

	record.sales_channel_stock_location_retrieve_params := ModelSalesChannelStockLocationRetrieveParams{
		sales_channel_ids_bin: [sales_channel_id.bytes()]
	}

	sales_channel_stock_locations := record.sales_channel_stock_location_retrieve(mut tx,
		record.sales_channel_stock_location_retrieve_params) or {
		tx.rollback() or {}
		perr := new_error_internal('Failed to retrieve sales_channel_stock_location', err.msg())
		return ctx.handle_error(perr)
	}

	tx.rollback() or {
		perr := new_error_internal(error_transaction_rollback, err.msg())
		return ctx.handle_error(perr)
	}

	assign_products_data(mut products_data, mut products_map)

	mut complete_products := []Product{len: products.len}
	for i := 0; i < products.len; i++ {
		id := products[i].id
		complete_products[i] = products_map[id.string()]
	}

	// variants_availability + prices
	mut variant_prices_map := map[string]VariantPrice{}
	mut complete_variants := []ProductVariant{len: products_data.variants.len}
	for i := 0; i < products_data.variants.len; i++ {
		variant := products_data.variants[i]
		complete_variants[i] = products_data.variants_map[variant.id.string()]
		price := calculate_price(variant, store.default_region_id, price_context, 1)
		variant_prices_map[variant.id.string()] = price
	}

	variants_availability := get_variants_availability(GetProductVariantsAvailabilityParams{
		variants:                      complete_variants
		sales_channel_ids_bin:         [sales_channel_id.bytes()]
		product_sales_channels:        products_data.product_sales_channels
		sales_channel_stock_locations: sales_channel_stock_locations
	})

	mut external_products := []ProductResponseStore{len: complete_products.len}
	for i := 0; i < complete_products.len; i++ {
		external_products[i] = format_product_response_store(complete_products[i], price_context,
			store.default_region_id, variants_availability, locale_context)
	}

	return ctx.json(ProductResponseStoreListEnvelope{
		products: external_products
		count:    count
		offset:   p.offset
		fetch:    p.fetch
	})
}

fn conduit_product_get_by_id(mut app App, mut ctx Context, p ProductRetrieveParams) !ProductResponse {
	mut tx := app.start_transaction()!

	products := record.product_retrieve(mut tx, p) or {
		tx.rollback() or {}
		return new_error_internal('Failed to retrieve products data', err.msg())
	}

	if products.len == 0 {
		tx.rollback() or {}
		return new_error_not_found('No product exists with the given id', 'products.len == 0')
	}

	mut product := products[0]
	mut product_data := suite_product_data_get(mut tx, [product.id]) or {
		tx.rollback() or {}
		return err
	}

	tx.rollback() or { return new_error_internal(error_transaction_rollback, err.msg()) }

	assign_product_data(mut product_data, mut product)

	// variants_availability
	mut complete_variants := []ProductVariant{len: product_data.variants.len}
	for i := 0; i < product_data.variants.len; i++ {
		variant_id := product_data.variants[i].id
		complete_variants[i] = product_data.variants_map[variant_id.string()]
	}

	product.variants = complete_variants

	external_product := format_product_response(product)

	return external_product
}

fn conduit_products_get_by_id_store(mut app App, mut ctx Context, p ProductRetrieveParams, sales_channel_id ID, price_context PriceContext, locale_context LocaleContext) veb.Result {
	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	// TODO get count first
	products := record.product_retrieve(mut tx, p) or {
		tx.rollback() or {}
		perr := new_error_internal('Failed to retrieve products data', err.msg())
		return ctx.handle_error(perr)
	}

	if products.len == 0 {
		perr := new_error_not_found('No product exists with the given id', 'products.len == 0')
		return ctx.handle_error(perr)
	}

	mut product := products[0]
	mut product_data := suite_product_data_get(mut tx, [product.id]) or {
		tx.rollback() or {}
		return ctx.handle_error(err)
	}

	store := record.store_retrieve(mut tx) or {
		tx.rollback() or {}
		perr := new_error_internal('could not retrieve store', err.msg())
		return ctx.handle_error(perr)
	}
	record.sales_channel_stock_location_retrieve_params := ModelSalesChannelStockLocationRetrieveParams{
		sales_channel_ids_bin: [sales_channel_id.bytes()]
	}
	sales_channel_stock_locations := record.sales_channel_stock_location_retrieve(mut tx,
		record.sales_channel_stock_location_retrieve_params) or {
		tx.rollback() or {}
		perr := new_error_internal('Failed to retrieve sales_channel_stock_location', err.msg())
		return ctx.handle_error(perr)
	}

	tx.rollback() or {
		perr := new_error_internal(error_transaction_rollback, err.msg())
		return ctx.handle_error(perr)
	}

	assign_product_data(mut product_data, mut product)

	mut variant_prices_map := map[string]VariantPrice{}
	mut complete_variants := []ProductVariant{len: product_data.variants.len}
	for i := 0; i < product_data.variants.len; i++ {
		variant := product_data.variants[i]
		complete_variants[i] = product_data.variants_map[variant.id.string()]
		price := calculate_price(variant, store.default_region_id, price_context, 1)
		variant_prices_map[variant.id.string()] = price
	}

	variants_availability := get_variants_availability(GetProductVariantsAvailabilityParams{
		variants:                      complete_variants
		sales_channel_ids_bin:         [sales_channel_id.bytes()]
		product_sales_channels:        product_data.product_sales_channels
		sales_channel_stock_locations: sales_channel_stock_locations
	})

	external_product := format_product_response_store(product, price_context,
		store.default_region_id, variants_availability, locale_context)

	return ctx.json(ProductResponseStoreEnvelope{
		product: external_product
	})
}

fn conduit_product_update(mut app App, mut ctx Context, mut tx firebird.Transaction, product_id ID, seo_id ID, product_diff ProductUpdateParams, images_diff []ProductImageUpdateParams, ph ProductUpdateRequestHygienised) ! {
	// always update the product row for `updated_at`
	record.product_update(mut tx, product_diff) or {
		return new_error_internal('Failed to update product', err.msg())
	}

	if ph.images != none {
		record.product_thumbnail_delete(mut tx, product_id) or {
			return new_error_internal('Failed to delete product thumbnail', err.msg())
		}

		if images_diff.len == 0 {
			record.product_images_delete(mut tx, product_id) or {
				return new_error_internal('Failed to delete product images', err.msg())
			}
		} else {
			record.product_images_update(mut tx, product_id, images_diff) or {
				return new_error_internal('Failed to update product images', err.msg())
			}

			if ph.thumbnail == none {
				record.product_thumbnail_update(mut tx, product_id, default_thumbnail) or {
					return new_error_internal('Failed to update product thumbnail', err.msg())
				}
			}
		}
	}

	if thumbnail := ph.thumbnail {
		record.product_thumbnail_update(mut tx, product_id, thumbnail) or {
			return new_error_internal('Failed to update product thumbnail', err.msg())
		}
	}

	if sales_channel_ids := ph.sales_channel_ids {
		record.product_sales_channel_update(mut tx, product_id, sales_channel_ids) or {
			return new_error_internal('Failed to update product sales channel', err.msg())
		}
	}

	if category_ids := ph.category_ids {
		record.category_product_update(mut tx, product_id, category_ids) or {
			return new_error_internal('Failed to update product category relation', err.msg())
		}
	}

	if translations := ph.translations {
		record.product_translations_delete(mut tx, product_id) or {
			return new_error_internal('Failed to delete from product_translations', err.msg())
		}

		if translations.len > 0 {
			record.product_translations_create(mut tx, product_id, translations) or {
				return new_error_internal('Failed to create product_translations', err.msg())
			}
		}
	}

	if seo := ph.seo {
		if seo.title != none || seo.description != none {
			record.seo_update(mut tx, seo_id, seo) or {
				return new_error_internal('Could not update seo', err.msg())
			}
		}

		if translations := seo.translations {
			record.product_seo_translations_delete(mut tx, product_id) or {
				return new_error_internal('Could not delete seo_translations', err.msg())
			}

			if translations.len > 0 {
				record.seo_translations_create(mut tx, seo_id, translations) or {
					return new_error_internal('Could not update seo_translations', err.msg())
				}
			}
		}
	}

	if options := ph.options {
		mut options_diff := []ProductOptionUpdateParams{len: options.len}
		mut option_ids := []ID{len: options_diff.len}

		old_options := record.product_option_retrieve(mut tx, [
			product_id.bytes(),
		]) or { return new_error_internal('Could not retrieve product_option', err.msg()) }

		mut old_options_map := map[string]ProductOption{}
		for i := 0; i < old_options.len; i++ {
			option := old_options[i]
			id := option.id
			old_options_map[id.string()] = option
		}

		for i := 0; i < options.len; i++ {
			option := options[i]
			id := option.id or {
				new_option_id := app.gen_id()
				options_diff[i] = ProductOptionUpdateParams{
					id:          new_option_id
					product_id:  product_id
					option_rank: i
					title:       string_value(option.title)
				}

				option_ids[i] = new_option_id
				continue
			}

			old_option := old_options_map[id.string()]
			options_diff[i] = ProductOptionUpdateParams{
				id:          id
				product_id:  product_id
				option_rank: i
				title:       unwrap_option_or(option.title, old_option.title)
			}

			option_ids[i] = id
		}

		record.product_option_update(mut tx, options_diff) or {
			return new_error_internal('Could not update product_option', err.msg())
		}

		// update translations if any option contains a translations object
		mut should_update_translations := false
		for i := 0; i < options.len; i++ {
			option := options[i]
			if option.translations != none {
				should_update_translations = true
				break
			}
		}

		if should_update_translations {
			old_translations := record.product_option_translations_retrieve(mut tx, [
				product_id.bytes(),
			]) or {
				return new_error_internal('Could not retrieve product_option_translations',
					err.msg())
			}

			mut option_translations_map := map[string][]ProductOptionTranslation{}
			for i := 0; i < old_translations.len; i++ {
				old_translation := old_translations[i]
				option_id := old_translation.product_option_id
				old_array := option_translations_map[option_id.string()]
				option_translations_map[option_id.string()] = arrays.concat(old_array,
					old_translation)
			}

			// preallocate
			mut n_translations := 0
			for i := 0; i < options.len; i++ {
				option := options[i]
				option_id := option.id or { options_diff[i].id }
				translations := option.translations or {
					n_translations += option_translations_map[option_id.string()].len
					continue
				}

				n_translations += translations.len
			}

			mut option_translations_diff := []ProductOptionTranslationParams{len: n_translations}
			mut translations_added := 0
			for i := 0; i < options.len; i++ {
				option := options[i]
				option_id := option.id or {
					new_option_id := options_diff[i].id
					if translations := option.translations {
						for j := 0; j < translations.len; j++ {
							translation := translations[j]
							option_translations_diff[translations_added] = ProductOptionTranslationParams{
								product_option_id: new_option_id
								locale_id:         translation.locale_id
								title:             translation.title
							}
							translations_added++
						}
					}
					continue
				}

				translations := option.translations or {
					old_option_translations := option_translations_map[option_id.string()]
					for j := 0; j < old_option_translations.len; j++ {
						old_translation := old_translations[j]
						option_translations_diff[translations_added] = ProductOptionTranslationParams{
							product_option_id: old_translation.product_option_id
							locale_id:         old_translation.locale_id
							title:             old_translation.title
						}
						translations_added++
					}
					continue
				}

				// if translations.len == 0 all translations for the option will be deleted.
				for j := 0; j < translations.len; j++ {
					translation := translations[j]
					option_translations_diff[translations_added] = ProductOptionTranslationParams{
						product_option_id: option_id
						locale_id:         translation.locale_id
						title:             translation.title
					}
					translations_added++
				}
			}

			option_translations_update_params := ProductOptionTranslationUpdateParams{
				product_option_ids: option_ids
				translations:       option_translations_diff
			}

			record.product_option_translations_update(mut tx, option_translations_update_params) or {
				return new_error_internal('Could not update product_option_translations', err.msg())
			}
		}

		mut should_update_values := false
		for i := 0; i < options.len; i++ {
			option := options[i]
			if option.values != none {
				should_update_values = true
			}
		}

		if should_update_values {
			mut n_values := 0
			for i := 0; i < options.len; i++ {
				option := options[i]
				if option.id == none { // new option, must have new values
					values := option.values or {
						return new_error_internal('New option has no values',
							'option.values == none')
					}

					n_values += values.len
					continue
				}

				values := option.values or {
					continue // no changes for this option
				}

				n_values += values.len // replace old values with new ones
			}

			old_values := record.product_option_values_retrieve(mut tx, ProductOptionValueRetrieveParams{
				option_ids: option_ids
			}) or {
				return new_error_internal('Could not retrieve product_option_values', err.msg())
			}

			mut old_values_map := map[string]ProductOptionValue{}
			for i := 0; i < old_values.len; i++ {
				old_value := old_values[i]
				old_value_id := old_value.id
				old_values_map[old_value_id.string()] = old_value
			}

			mut values_diff := []ProductOptionValueUpdateParams{len: n_values}
			mut values_added := 0
			for i := 0; i < options.len; i++ {
				option := options[i]
				option_id := option.id or {
					new_option := options_diff[i]
					values := option.values or {
						return new_error_internal('New option has no values',
							'option.values == none')
					}

					for j := 0; j < values.len; j++ {
						value := values[j]
						new_value_id := app.gen_id()
						values_diff[values_added] = ProductOptionValueUpdateParams{
							id:         new_value_id
							option_id:  new_option.id
							value_rank: j
							name:       string_value(value.name)
						}
					}
					values_added++
					continue
				}

				values := option.values or { continue }

				for j := 0; j < values.len; j++ {
					value := values[j]
					value_id := value.id or {
						new_value_id := app.gen_id()
						values_diff[values_added] = ProductOptionValueUpdateParams{
							id:         new_value_id
							option_id:  option_id
							value_rank: j
							name:       string_value(value.name)
						}
						values_added++
						continue
					}

					old_value := old_values_map[value_id.string()]
					values_diff[values_added] = ProductOptionValueUpdateParams{
						id:         value_id
						option_id:  option_id
						value_rank: j
						name:       unwrap_option_or(value.name, old_value.name)
					}
					values_added++
				}
			}

			record.product_option_value_update(mut tx, values_diff) or {
				return new_error_internal('Could not update product_option_value', err.msg())
			}

			// value translations
			mut n_value_translations := 0
			for i := 0; i < options.len; i++ {
				option := options[i]
				values := option.values or { continue }

				for j := 0; j < values.len; j++ {
					value := values[i]
					translations := value.translations or { continue }
					n_value_translations += translations.len
				}
			}

			mut value_translations_diff := []ProductOptionValueTranslationParams{len: n_value_translations}
			mut current_value_index := 0
			mut value_translations_added := 0
			for i := 0; i < options.len; i++ {
				option := options[i]
				values := option.values or { continue }

				for j := 0; j < values.len; j++ {
					value := values[j]
					// need value id
					product_option_value_id := values_diff[current_value_index].id
					translations := value.translations or { continue }

					// if translations.len == 0 all translations for the value will be deleted.
					for k := 0; k < translations.len; k++ {
						translation := translations[k]
						value_translations_diff[value_translations_added] = ProductOptionValueTranslationParams{
							product_option_value_id: product_option_value_id
							locale_id:               translation.locale_id
							name:                    translation.name
						}
						value_translations_added++
					}
					current_value_index++
				}
			}

			mut value_ids := []ID{len: values_diff.len}
			for i := 0; i < values_diff.len; i++ {
				value_ids[i] = values_diff[i].id
			}

			option_value_translation_update_params := ProductOptionValueTranslationUpdateParams{
				product_option_value_ids: value_ids
				translations:             value_translations_diff
			}

			record.product_option_value_translations_update(mut tx,
				option_value_translation_update_params) or {
				return new_error_internal('Could not update option_value_translations', err.msg())
			}
		}
	}

	if variants := ph.variants {
		mut variants_diff := []VariantUpdateParams{len: variants.len}
		mut inventory_items_diff := []InventoryItemUpdateParams{len: variants.len}
		// TODO get options and option values to create relations

		// TODO loop for pagination
		old_variants := record.variant_retrieve(mut tx, VariantRetrieveParams{
			product_ids:  [product_id]
			with_deleted: false
			offset:       offset_default
			fetch:        max_fetch
			order:        order_default
		}) or { return new_error_internal('Could not retrieve variants', err.msg()) }

		old_variants_map, old_variants_ids := make_identifiable_map(old_variants)

		old_inventory_items := record.inventory_item_retrieve(mut tx, old_variants_ids) or {
			return new_error_internal('Could not retrieve inventory items', err.msg())
		}

		mut old_inventory_items_map := map[string]InventoryItem{}
		for i := 0; i < old_inventory_items.len; i++ {
			inventory_item := old_inventory_items[i]
			variant_id := inventory_item.variant_id
			old_inventory_items_map[variant_id.string()] = inventory_item
		}

		for i := 0; i < variants.len; i++ {
			variant := variants[i]
			if variant_id := variant.id {
				// update variant
				old_variant := old_variants_map[variant_id.string()]

				mut image_id := old_variant.image_id
				if image := variant.image {
					image_id = images_diff[image].id
				}

				variants_diff[i] = VariantUpdateParams{
					id:           variant_id
					image_id:     image_id
					title:        unwrap_option_or(variant.title, old_variant.title.value)
					barcode:      unwrap_option_or(variant.barcode, old_variant.barcode.value)
					ean:          unwrap_option_or(variant.ean, old_variant.ean.value)
					upc:          unwrap_option_or(variant.upc, old_variant.upc.value)
					variant_rank: i
					metadata:     unwrap_option_or(variant.metadata, old_variant.metadata.value)
				}

				old_inventory_item := old_inventory_items_map[variant_id.string()]
				if inventory_item := variant.inventory_item {
					inventory_items_diff[i] = InventoryItemUpdateParams{
						id:                old_inventory_item.id
						variant_id:        variant_id
						sku:               unwrap_option_or(inventory_item.sku,
							old_inventory_item.sku.value)
						origin_country:    unwrap_option_or(inventory_item.origin_country,
							old_inventory_item.origin_country.value)
						hs_code:           unwrap_option_or(inventory_item.hs_code,
							old_inventory_item.hs_code.value)
						mid_code:          unwrap_option_or(inventory_item.mid_code,
							old_inventory_item.mid_code.value)
						material:          unwrap_option_or(inventory_item.material,
							old_inventory_item.material.value)
						weight:            unwrap_option_or(inventory_item.weight,
							old_inventory_item.weight.value)
						length:            unwrap_option_or(inventory_item.length,
							old_inventory_item.length.value)
						height:            unwrap_option_or(inventory_item.height,
							old_inventory_item.height.value)
						width:             unwrap_option_or(inventory_item.width,
							old_inventory_item.width.value)
						requires_shipping: unwrap_option_or(inventory_item.requires_shipping,
							old_inventory_item.requires_shipping)
						manage_inventory:  unwrap_option_or(inventory_item.manage_inventory,
							old_inventory_item.manage_inventory)
						allow_backorder:   unwrap_option_or(inventory_item.allow_backorder,
							old_inventory_item.allow_backorder)
					}
				} else {
					inventory_items_diff[i] = InventoryItemUpdateParams{
						id:                old_inventory_item.id
						variant_id:        variant_id
						sku:               old_inventory_item.sku.value
						origin_country:    old_inventory_item.origin_country.value
						hs_code:           old_inventory_item.hs_code.value
						mid_code:          old_inventory_item.mid_code.value
						material:          old_inventory_item.material.value
						weight:            old_inventory_item.weight.value
						length:            old_inventory_item.length.value
						height:            old_inventory_item.height.value
						width:             old_inventory_item.width.value
						requires_shipping: old_inventory_item.requires_shipping
						manage_inventory:  old_inventory_item.manage_inventory
						allow_backorder:   old_inventory_item.allow_backorder
					}
				}
			} else {
				new_variant_id := app.gen_id()

				mut image_id := ?ID(none)
				if image := variant.image {
					image_id = images_diff[image].id
				}

				variants_diff[i] = VariantUpdateParams{
					id:           new_variant_id
					image_id:     image_id
					title:        string_value(variant.title)
					barcode:      string_value(variant.barcode)
					ean:          string_value(variant.ean)
					upc:          string_value(variant.upc)
					variant_rank: i
					metadata:     string_value(variant.metadata)
				}

				new_inventory_item_id := app.gen_id()
				if inventory_item := variant.inventory_item {
					inventory_items_diff[i] = InventoryItemUpdateParams{
						id:                new_inventory_item_id
						variant_id:        new_variant_id
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
					inventory_items_diff[i] = InventoryItemUpdateParams{
						id:                new_inventory_item_id
						variant_id:        new_variant_id
						requires_shipping: true
						manage_inventory:  true
						allow_backorder:   false
					}
				}
			}
		}

		record.product_variant_update(mut tx, product_id, variants_diff) or {
			return new_error_internal('Failed to update variants', err.msg())
		}

		record.inventory_item_update(mut tx, inventory_items_diff) or {
			return new_error_internal('Failed to update inventory items', err.msg())
		}

		record.inventory_item_sync_delete(mut tx, product_id) or {
			return new_error_internal('Failed to delete inventory items', err.msg())
		}

		// product_option_value_variant
		// get all options for the product, they're returned by firebird sorted by option_rank.
		options := record.product_option_retrieve(mut tx, [
			product_id.bytes(),
		]) or { return new_error_internal('Failed to retrieve product_option', err.msg()) }

		mut options_map, product_option_ids := make_identifiable_map(options)

		// get all values for the options, they're returned by firebird sorted by value_rank.
		values := record.product_option_values_retrieve(mut tx, ProductOptionValueRetrieveParams{
			option_ids: product_option_ids
		}) or { return new_error_internal('Failed to retrieve product_option_value', err.msg()) }

		for i := 0; i < values.len; i++ {
			value := values[i]
			option_id := value.option_id.string()
			option_old := options_map[option_id].values
			options_map[option_id].values = arrays.concat(option_old, value)
		}

		mut n_variants := 0
		mut n_relations := 0
		for i := 0; i < variants.len; i++ {
			variant := variants[i]
			option_values := variant.option_values or { continue }
			n_variants++
			n_relations += option_values.len
		}

		mut variant_ids := []ID{len: n_variants}
		mut variants_added := 0
		mut relations := []ProductOptionValueProductVariant{len: n_relations}
		mut relations_added := 0
		for i := 0; i < variants.len; i++ {
			variant := variants[i]
			option_values := variant.option_values or { continue }
			variant_id := variants_diff[i].id
			variant_ids[variants_added] = variant_id
			for j := 0; j < option_values.len; j++ {
				option_index := j
				value_index := option_values[j] // bounds check in validation step
				option := options[option_index] // bounds check in validation step
				option_id := option.id.string()
				values_of_option := options_map[option_id].values // existance check in validation step
				value := values_of_option[value_index]
				relations[relations_added] = ProductOptionValueProductVariant{
					variant_id:      variant_id
					option_value_id: value.id
				}
				relations_added++
			}
			variants_added++
		}

		if n_variants > 0 {
			record.product_option_value_variant_update(mut tx, ProductOptionValueProductVariantParams{
				variant_ids: variant_ids
				relations:   relations
			}) or {
				return new_error_internal('Failed to update product_option_value_product_variant',
					err.msg())
			}
		}

		// variant_money_amount
		mut n_money_amounts := 0
		for i := 0; i < variants.len; i++ {
			variant := variants[i]
			money_amounts := variant.money_amounts or { continue }
			n_money_amounts += money_amounts.len
		}

		mut variant_money_amounts := []VariantMoneyAmountUpdateParams{len: n_money_amounts}
		mut money_amounts_added := 0
		for i := 0; i < variants.len; i++ {
			variant := variants[i]
			variant_id := variants_diff[i].id
			money_amounts := variant.money_amounts or { continue }
			for j := 0; j < money_amounts.len; j++ {
				money_amount := money_amounts[j]
				money_amount_id := app.gen_id()
				variant_money_amounts[money_amounts_added] = VariantMoneyAmountUpdateParams{
					variant_id:      variant_id
					region_id:       money_amount.region_id
					money_amount_id: money_amount_id
					amount:          money_amount.amount
					is_original:     bool_or(money_amount.is_original, false)
				}
				money_amounts_added++
			}
		}

		if n_money_amounts > 0 {
			record.variant_money_amount_update(mut tx, variant_money_amounts) or {
				return new_error_internal('Failed to update variant_money_amount', err.msg())
			}
		}
	}
}

fn conduit_product_delete(mut app App, mut ctx Context, product_id ID) ! {
	mut tx := app.start_transaction()!

	record.product_delete(mut tx, product_id) or {
		tx.rollback() or {}
		return new_error_internal('Failed to delete product', err.msg())
	}

	tx.commit() or { return new_error_internal(error_transaction_commit, err.msg()) }
}

