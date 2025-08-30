module peony

import arrays

struct ProductVariantAvailability {
	purchasable        bool
	inventory_quantity i32
}

fn get_product_variant_availability(product_variant ProductVariant,
	allowed_stock_locations [][]u8) ProductVariantAvailability {
	inventory_item := product_variant.inventory_item
	if !inventory_item.manage_inventory {
		return ProductVariantAvailability{
			purchasable:        true
			inventory_quantity: 0
		}
	}

	inventory_levels := inventory_item.inventory_levels
	if inventory_levels.len == 0 {
		return ProductVariantAvailability{
			purchasable:        false
			inventory_quantity: 0
		}
	}

	mut inventory_quantity := i32(0)
	for i := 0; i < inventory_levels.len; i++ {
		inventory_level := inventory_levels[i]
		if allowed_stock_locations.contains(inventory_level.stock_location_id_bin) {
			inventory_quantity += (inventory_level.stocked_quantity - inventory_level.reserved_quantity)
		}
	}

	if inventory_quantity == 0 {
		if inventory_item.allow_backorder {
			return ProductVariantAvailability{
				purchasable:        true
				inventory_quantity: 0
			}
		}
		return ProductVariantAvailability{
			purchasable:        false
			inventory_quantity: 0
		}
	}

	return ProductVariantAvailability{
		purchasable:        true
		inventory_quantity: inventory_quantity
	}
}

struct GetProductVariantsAvailabilityParams {
	product_sales_channels        []ProductSalesChannel
	sales_channel_stock_locations []SalesChannelStockLocation
}

// get_product_variants_availability:
//  1. Gathers all p.product_sales_channels entries where sales_channel_id_bin matches.
//  2. Gathers all p.sales_channel_stock_locations entries where sales_channel_id_bin matches.
//  3. For each v in product_variants:
//     a) If v.product_id_bin not in products_in_channel:
//          result[v.id] = ProductVariantAvailability{ purchasable: false, inventory_quantity: 0 }
//     b) Else if v.inventory_item.manage_inventory == false:
//          result[v.id] = ProductVariantAvailability{ purchasable: true, inventory_quantity: 0 }
//     c) Else:
//          i.  Filter v.inventory_item.inventory_levels by lvl.stock_location_id in allowed_locations.
//         ii.  If filtered_levels.len == 0:
//               result[v.id] = ProductVariantAvailability{ purchasable: false, inventory_quantity: 0 }
//        iii.  Sum total_qty = Σ (lvl.stocked_quantity - lvl.reserved_quantity).
//         iv.  If total_qty == 0 && v.inventory_item.allow_backorder:
//               result[v.id] = ProductVariantAvailability{ purchasable: true, inventory_quantity: 0 }
//          v.  Else if total_qty == 0:
//               result[v.id] = ProductVariantAvailability{ purchasable: false, inventory_quantity: 0 }
//         vi.  Else:
//               result[v.id] = ProductVariantAvailability{ purchasable: true, inventory_quantity: total_qty }
//  4. Return the result map.
fn get_product_variants_availability(product_variants []ProductVariant,
	sales_channel_ids_bin [][]u8, p GetProductVariantsAvailabilityParams) map[string]ProductVariantAvailability {
	mut products_in_sales_channels := [][]u8{}
	for i := 0; i < p.product_sales_channels.len; i++ {
		psc := p.product_sales_channels[i]
		if sales_channel_ids_bin.contains(psc.sales_channel_id_bin)
			&& !products_in_sales_channels.contains(psc.product_id_bin) {
			products_in_sales_channels = arrays.concat(products_in_sales_channels, psc.product_id_bin)
		}
	}

	mut allowed_stock_locations := [][]u8{}
	for i := 0; i < p.sales_channel_stock_locations.len; i++ {
		scsl := p.sales_channel_stock_locations[i]
		if sales_channel_ids_bin.contains(scsl.sales_channel_id_bin)
			&& !allowed_stock_locations.contains(scsl.stock_location_id_bin) {
			allowed_stock_locations = arrays.concat(allowed_stock_locations, scsl.stock_location_id_bin)
		}
	}

	mut res := map[string]ProductVariantAvailability{}
	for i := 0; i < product_variants.len; i++ {
		product_variant := product_variants[i]
		if products_in_sales_channels.contains(product_variant.product_id_bin) {
			res[product_variant.id] = get_product_variant_availability(product_variant,
				allowed_stock_locations)
		} else {
			res[product_variant.id] = ProductVariantAvailability{
				purchasable:        false
				inventory_quantity: 0
			}
		}
	}
	return res
}
