module peony

import einar_hjortdal.firebird

fn conduit_variant_get(mut app App, mut ctx Context, mut tx firebird.Transaction, ph RetrieveProductVariantParamsHygienised) !ProductVariant {
	count := model_product_variants_retrieve_count(mut tx, ph) or {
		return new_error_internal('Could not retrieve product_variant count', err.msg())
	}

	if count == 0 {
		return new_error_not_found('No variant exists with the given id', 'count == 0')
	}

	variants := model_product_variants_retrieve(mut tx, ph) or {
		return new_error_internal('Could not retrieve product_variant', err.msg())
	}

	money_amounts := model_variant_money_amount_retrieve(mut tx, ph.ids_bin) or {
		return new_error_internal('Could not retrieve product_variant_money_amount', err.msg())
	}

	inventory_items := model_inventory_item_retrieve(mut tx, ph.ids_bin) or {
		return new_error_internal('Could not retrieve inventory_item', err.msg())
	}

	if inventory_items.len == 0 {
		return new_error_internal(error_database_data_malformed, 'inventory_items.len == 0')
	}

	mut inventory_item := inventory_items[0]
	inventory_levels := model_inventory_level_get(mut tx, [inventory_item.id_bin]) or {
		return new_error_internal('Could not retrieve inventory_level', err.msg())
	}

	mut variant := variants[0]
	inventory_item.inventory_levels = inventory_levels
	variant.money_amounts = money_amounts
	variant.inventory_item = inventory_item

	return variant
}

fn conduit_variant_create(mut app App, mut ctx Context, mut tx firebird.Transaction, product_id string, product_id_bin []u8, variant_id string, variant_id_bin []u8, ph VariantCreateRequestHygienised) ! {
	mut image_id_bin := []u8{}
	if ph.image_id_bin.len > 0 {
		image_id_bin = &ph.image_id_bin
	}

	variant_to_create := VariantCreateParams{
		product_id:     product_id
		product_id_bin: product_id_bin
		variant_id:     variant_id
		variant_id_bin: variant_id_bin
		image_id:       string_value(ph.image_id)
		image_id_bin:   image_id_bin
		title:          string_value(ph.title)
		barcode:        string_value(ph.barcode)
		ean:            string_value(ph.ean)
		upc:            string_value(ph.upc)
		metadata:       string_value(ph.metadata)
		variant_rank:   0 // Explicit
	}
	variants_to_create := [variant_to_create]
	model_variant_create(mut tx, variants_to_create) or {
		return new_error_internal('Could not create product_variant', err.msg())
	}

	inventory_item_id, inventory_item_id_bin := app.new_id()
	if inventory_item := ph.inventory_item {
		model_inventory_item_create(mut tx, [
			InventoryItemCreateParams{
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
			},
		]) or {
			return new_error_internal('Could not create inventory_item for product_variant',
				err.msg())
		}
	} else {
		model_inventory_item_create(mut tx, [
			InventoryItemCreateParams{
				id:                inventory_item_id
				id_bin:            inventory_item_id_bin
				variant_id:        variant_id
				variant_id_bin:    variant_id_bin
				requires_shipping: true
				manage_inventory:  true
				allow_backorder:   false
			},
		]) or {
			return new_error_internal('Could not create inventory_item for product_variant',
				err.msg())
		}

		if money_amounts := ph.money_amounts {
			mut variant_money_amount_update_params := []VariantMoneyAmountUpdateParams{len: money_amounts.len}
			for i := 0; i < money_amounts.len; i++ {
				money_amount := money_amounts[i]
				id, id_bin := app.new_id()
				variant_money_amount_update_params[i] = VariantMoneyAmountUpdateParams{
					variant_id:          variant_id
					variant_id_bin:      variant_id_bin
					region_id:           money_amount.region_id
					region_id_bin:       money_amount.region_id_bin
					money_amount_id:     id
					money_amount_id_bin: id_bin
					amount:              money_amount.amount
					is_original:         money_amount.is_original
				}
			}
			model_variant_money_amount_update(mut tx, variant_money_amount_update_params) or {
				return new_error_internal('Could not update money_amounts', err.msg())
			}
		} else {
			regions := model_region_retrieve(mut tx, RegionRetriveParams{
				fetch: max_fetch
			}) or { return new_error_internal('Could not retrieve regions', err.msg()) }

			if regions.len == 0 {
				return new_error_internal('Database contains no regions', err.msg())
			}

			mut variant_money_amount_update_params := []VariantMoneyAmountUpdateParams{len: regions.len}
			for i := 0; i < regions.len; i++ {
				region := regions[i]
				id, id_bin := app.new_id()
				variant_money_amount_update_params[i] = VariantMoneyAmountUpdateParams{
					variant_id:          variant_id
					variant_id_bin:      variant_id_bin
					region_id:           region.id
					region_id_bin:       region.id_bin
					money_amount_id:     id
					money_amount_id_bin: id_bin
					amount:              0
					is_original:         false
				}
			}

			model_variant_money_amount_update(mut tx, variant_money_amount_update_params) or {
				return new_error_internal('Could not create default money_amounts for the new variant',
					err.msg())
			}
		}
	}
}

fn conduit_variant_update(mut app App, mut ctx Context, mut tx firebird.Transaction, product_id_bin []u8, variant_id string, variant_id_bin []u8, variant ProductVariant, ph VariantUpdateRequestHygienised) ! {
	mut image_id_bin := &variant.image_id_bin
	if ph.image_id != none {
		image_id_bin = &ph.image_id_bin
	}

	variant_diff := VariantUpdateParams{
		id:           variant_id
		id_bin:       variant_id_bin
		image_id:     unwrap_option_or(ph.image_id, variant.image_id)
		image_id_bin: image_id_bin
		title:        unwrap_option_or(ph.title, variant.title.value)
		barcode:      unwrap_option_or(ph.barcode, variant.barcode.value)
		ean:          unwrap_option_or(ph.ean, variant.ean.value)
		upc:          unwrap_option_or(ph.upc, variant.upc.value)
		variant_rank: variant.variant_rank
		metadata:     unwrap_option_or(ph.metadata, variant.metadata.value)
	}
	model_variant_update(mut tx, variant_id_bin, variant_diff) or {
		return new_error_internal('Could not update product_variant', err.msg())
	}

	if option_value_ids := ph.option_value_ids {
		mut relations := []ProductOptionValueProductVariant{len: option_value_ids.len}
		for i := 0; i < option_value_ids.len; i++ {
			relations[i] = ProductOptionValueProductVariant{
				option_value_id:     option_value_ids[i]
				option_value_id_bin: ph.option_value_ids_bin[i]
				variant_id:          variant_id
				variant_id_bin:      variant_id_bin
			}
		}

		model_product_option_value_variant_update(mut tx, ProductOptionValueProductVariantParams{
			variant_ids:     [variant_id]
			variant_ids_bin: [variant_id_bin]
			relations:       relations
		}) or { return new_error_internal('Could not update product_option_value', err.msg()) }
	}

	if inventory_item := ph.inventory_item {
		inventory_items := model_inventory_item_retrieve(mut tx, [variant_id_bin]) or {
			return new_error_internal('Could not retrieve inventory_item', err.msg())
		}

		if inventory_items.len != 1 {
			return new_error_internal('Unexpected inventory item count', 'inventory_items.len != 1')
		}

		old := inventory_items[0]
		inventory_item_diff := InventoryItemUpdateParams{
			id:                old.id
			id_bin:            old.id_bin
			variant_id:        variant_id
			variant_id_bin:    variant_id_bin
			sku:               unwrap_option_or(inventory_item.sku, old.sku.value)
			origin_country:    unwrap_option_or(inventory_item.origin_country, old.origin_country.value)
			hs_code:           unwrap_option_or(inventory_item.hs_code, old.hs_code.value)
			mid_code:          unwrap_option_or(inventory_item.mid_code, old.mid_code.value)
			material:          unwrap_option_or(inventory_item.material, old.material.value)
			weight:            unwrap_option_or(inventory_item.weight, old.weight.value)
			length:            unwrap_option_or(inventory_item.length, old.length.value)
			height:            unwrap_option_or(inventory_item.height, old.height.value)
			width:             unwrap_option_or(inventory_item.width, old.width.value)
			requires_shipping: unwrap_option_or(inventory_item.requires_shipping, old.requires_shipping)
			manage_inventory:  unwrap_option_or(inventory_item.manage_inventory, old.manage_inventory)
			allow_backorder:   unwrap_option_or(inventory_item.allow_backorder, old.allow_backorder)
		}

		model_inventory_item_update(mut tx, [inventory_item_diff]) or {
			return new_error_internal('Could not update inventory_item', err.msg())
		}
	}

	if money_amounts := ph.money_amounts {
		mut variant_money_amount_update_params := []VariantMoneyAmountUpdateParams{len: money_amounts.len}
		for i := 0; i < money_amounts.len; i++ {
			money_amount := money_amounts[i]
			id, id_bin := app.new_id()
			variant_money_amount_update_params[i] = VariantMoneyAmountUpdateParams{
				variant_id:          variant_id
				variant_id_bin:      variant_id_bin
				region_id:           money_amount.region_id
				region_id_bin:       money_amount.region_id_bin
				money_amount_id:     id
				money_amount_id_bin: id_bin
				amount:              money_amount.amount
				is_original:         money_amount.is_original
			}
		}
		model_variant_money_amount_update(mut tx, variant_money_amount_update_params) or {
			return new_error_internal('Could not update money_amounts', err.msg())
		}
	}
}

fn conduit_variant_delete(mut app App, mut ctx Context, mut tx firebird.Transaction, variant_id_bin []u8) ! {
	model_variant_delete(mut tx, variant_id_bin) or {
		return new_error_internal('Could not delete variant', err.msg())
	}
}
