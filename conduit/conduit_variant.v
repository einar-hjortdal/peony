module peony

import arrays
import einar_hjortdal.firebird
import record

pub type Variant = record.Variant

pub type VariantRetrieveParams = record.VariantRetrieveParams

pub fn variant_get(mut tx firebird.Transaction, variant_id ID) !Variant {
	variants := record.variant_retrieve(mut tx, VariantRetrieveParams{
		ids:          [variant_id]
		with_deleted: false
		offset:       offset_default
		fetch:        1
		order:        order_default
	}) or { return new_error_internal('Could not retrieve product_variant', err.msg()) }

	if variants.len == 0 {
		return new_error_not_found('No variant found',
			'No variant exists with id `${variant_id.string()}`')
	}

	money_amounts := record.variant_money_amount_retrieve(mut tx, [variant_id]) or {
		return new_error_internal('Could not retrieve product_variant_money_amount', err.msg())
	}

	inventory_items := record.inventory_item_retrieve(mut tx, [variant_id]) or {
		return new_error_internal('Could not retrieve inventory_item', err.msg())
	}

	if inventory_items.len == 0 {
		return new_error_internal(error_database_data_malformed, 'inventory_items.len == 0')
	}

	mut inventory_item := inventory_items[0]
	inventory_levels := record.inventory_level_get(mut tx, [inventory_item.id]) or {
		return new_error_internal('Could not retrieve inventory_level', err.msg())
	}

	mut variant := variants[0]
	inventory_item.inventory_levels = inventory_levels
	variant.money_amounts = money_amounts
	variant.inventory_item = inventory_item

	option_value_variants := record.product_option_value_variant_retrieve(mut tx, ProductOptionValueVariantRetrieveParams{
		variant_ids: [variant.id]
	}) or {
		return new_error_internal('Could not retrieve product_option_value_variant', err.msg())
	}

	mut option_value_ids := []ID{len: option_value_variants.len}
	for i := 0; i < option_value_variants.len; i++ {
		option_value_variant := option_value_variants[i]
		option_value_ids[i] = option_value_variant.option_value_id
	}

	option_values := record.product_option_values_retrieve(mut tx, ProductOptionValueRetrieveParams{
		ids: option_value_ids
	}) or { return new_error_internal('Could not retrieve product_option_value', err.msg()) }

	option_value_translations := record.product_option_value_translations_retrieve(mut tx,
		option_value_ids) or {
		return new_error_internal('Could not retrieve product_option_value_translations', err.msg())
	}

	mut option_values_map, _ := make_identifiable_map(option_values)

	for i := 0; i < option_value_translations.len; i++ {
		translation := option_value_translations[i]
		option_value_id := translation.option_value_id
		old := option_values_map[option_value_id.string()].translations
		option_values_map[option_value_id.string()].translations = arrays.concat(old, translation)
	}

	mut complete_option_values := []ProductOptionValue{len: option_value_ids.len}
	for i := 0; i < option_value_ids.len; i++ {
		option_value_id := option_value_ids[i]
		complete_option_values[i] = option_values_map[option_value_id.string()]
	}

	variant.option_values = complete_option_values

	return variant
}

fn variant_create(mut tx firebird.Transaction, product_id ID, variant_id ID, ph VariantCreateRequestHygienised) ! {
	variant_to_create := VariantCreateParams{
		product_id:   product_id
		variant_id:   variant_id
		image_id:     ph.image_id
		title:        string_value(ph.title)
		barcode:      string_value(ph.barcode)
		ean:          string_value(ph.ean)
		upc:          string_value(ph.upc)
		metadata:     string_value(ph.metadata)
		variant_rank: 0 // Explicit
	}
	variants_to_create := [variant_to_create]
	record.variant_create(mut tx, variants_to_create) or {
		return new_error_internal('Could not create product_variant', err.msg())
	}

	inventory_item_id := app.gen_id()
	if inventory_item := ph.inventory_item {
		record.inventory_item_create(mut tx, [
			InventoryItemCreateParams{
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
			},
		]) or {
			return new_error_internal('Could not create inventory_item for product_variant',
				err.msg())
		}
	} else {
		record.inventory_item_create(mut tx, [
			InventoryItemCreateParams{
				id:                inventory_item_id
				variant_id:        variant_id
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
				id := app.gen_id()
				variant_money_amount_update_params[i] = VariantMoneyAmountUpdateParams{
					variant_id:      variant_id
					region_id:       money_amount.region_id
					money_amount_id: id
					amount:          money_amount.amount
					is_original:     money_amount.is_original
				}
			}
			record.variant_money_amount_update(mut tx, variant_money_amount_update_params) or {
				return new_error_internal('Could not update money_amounts', err.msg())
			}
		} else {
			regions := record.region_retrieve(mut tx, RegionRetriveParams{
				fetch: max_fetch
				order: order_default
			}) or { return new_error_internal('Could not retrieve regions', err.msg()) }

			if regions.len == 0 {
				return new_error_internal('Database contains no regions', err.msg())
			}

			mut variant_money_amount_update_params := []VariantMoneyAmountUpdateParams{len: regions.len}
			for i := 0; i < regions.len; i++ {
				region := regions[i]
				id := app.gen_id()
				variant_money_amount_update_params[i] = VariantMoneyAmountUpdateParams{
					variant_id:      variant_id
					region_id:       region.id
					money_amount_id: id
					amount:          0
					is_original:     false
				}
			}

			record.variant_money_amount_update(mut tx, variant_money_amount_update_params) or {
				return new_error_internal('Could not create default money_amounts for the new variant',
					err.msg())
			}
		}
	}
}

fn conduit_variant_update(mut tx firebird.Transaction, product_id ID, variant_id ID, variant Variant, ph VariantUpdateRequestHygienised) ! {
	mut updated_image_id := variant.image_id
	if image_id := ph.image_id {
		updated_image_id = ph.image_id
	}

	variant_diff := VariantUpdateParams{
		id:           variant_id
		image_id:     updated_image_id
		title:        unwrap_option_or(ph.title, variant.title.value)
		barcode:      unwrap_option_or(ph.barcode, variant.barcode.value)
		ean:          unwrap_option_or(ph.ean, variant.ean.value)
		upc:          unwrap_option_or(ph.upc, variant.upc.value)
		variant_rank: variant.variant_rank
		metadata:     unwrap_option_or(ph.metadata, variant.metadata.value)
	}
	record.variant_update(mut tx, variant_diff) or {
		return new_error_internal('Could not update product_variant', err.msg())
	}

	if option_value_ids := ph.option_value_ids {
		mut relations := []ProductOptionValueProductVariant{len: option_value_ids.len}
		for i := 0; i < option_value_ids.len; i++ {
			relations[i] = ProductOptionValueProductVariant{
				option_value_id: option_value_ids[i]
				variant_id:      variant_id
			}
		}

		record.product_option_value_variant_update(mut tx, ProductOptionValueProductVariantParams{
			variant_ids: [variant_id]
			relations:   relations
		}) or { return new_error_internal('Could not update product_option_value', err.msg()) }
	}

	if inventory_item := ph.inventory_item {
		inventory_items := record.inventory_item_retrieve(mut tx, [variant_id]) or {
			return new_error_internal('Could not retrieve inventory_item', err.msg())
		}

		if inventory_items.len != 1 {
			return new_error_internal('Unexpected inventory item count', 'inventory_items.len != 1')
		}

		old := inventory_items[0]
		inventory_item_diff := InventoryItemUpdateParams{
			id:                old.id
			variant_id:        variant_id
			sku:               unwrap_option_or(inventory_item.sku, old.sku.value)
			origin_country:    unwrap_option_or(inventory_item.origin_country,
				old.origin_country.value)
			hs_code:           unwrap_option_or(inventory_item.hs_code, old.hs_code.value)
			mid_code:          unwrap_option_or(inventory_item.mid_code, old.mid_code.value)
			material:          unwrap_option_or(inventory_item.material, old.material.value)
			weight:            unwrap_option_or(inventory_item.weight, old.weight.value)
			length:            unwrap_option_or(inventory_item.length, old.length.value)
			height:            unwrap_option_or(inventory_item.height, old.height.value)
			width:             unwrap_option_or(inventory_item.width, old.width.value)
			requires_shipping: unwrap_option_or(inventory_item.requires_shipping,
				old.requires_shipping)
			manage_inventory:  unwrap_option_or(inventory_item.manage_inventory,
				old.manage_inventory)
			allow_backorder:   unwrap_option_or(inventory_item.allow_backorder, old.allow_backorder)
		}

		record.inventory_item_update(mut tx, [inventory_item_diff]) or {
			return new_error_internal('Could not update inventory_item', err.msg())
		}
	}

	if money_amounts := ph.money_amounts {
		mut variant_money_amount_update_params := []VariantMoneyAmountUpdateParams{len: money_amounts.len}
		for i := 0; i < money_amounts.len; i++ {
			money_amount := money_amounts[i]
			id := app.gen_id()
			variant_money_amount_update_params[i] = VariantMoneyAmountUpdateParams{
				variant_id:      variant_id
				region_id:       money_amount.region_id
				money_amount_id: id
				amount:          money_amount.amount
				is_original:     money_amount.is_original
			}
		}
		record.variant_money_amount_update(mut tx, variant_money_amount_update_params) or {
			return new_error_internal('Could not update money_amounts', err.msg())
		}
	}
}

fn conduit_variant_delete(mut tx firebird.Transaction, variant_id ID) ! {
	record.variant_delete(mut tx, variant_id) or {
		return new_error_internal('Could not delete variant', err.msg())
	}
}

