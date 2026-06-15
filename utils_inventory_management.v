module peony

import arrays
import internal.conduit

// used by admin endpoints.
// returns available items across all stock locations.
// an available item is not reserved.
// returns 0 if peony does not manage the inventory for this variant.
fn get_inventory_quantity(v conduit.InventoryItem) i32 {
	mut inventory_quantity := i32(0)
	if !v.manage_inventory {
		return inventory_quantity
	}

	for i := 0; i < v.inventory_levels.len; i++ {
		inventory_level := v.inventory_levels[i]
		available := inventory_level.stocked_quantity - inventory_level.reserved_quantity
		inventory_quantity += available
	}
	return inventory_quantity
}

struct ProductVariantAvailability {
	purchasable        bool
	inventory_quantity i32
}

// used by store endpoints
fn get_variant_availability(variant ProductVariant,
	allowed_stock_locations [][]u8) ProductVariantAvailability {
	inventory_item := variant.inventory_item
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

// TODO should only accept one sales_channel_id_bin
struct GetProductVariantsAvailabilityParams {
	variants                      []ProductVariant
	sales_channel_ids_bin         [][]u8
	product_sales_channels        []ProductSalesChannel
	sales_channel_stock_locations []SalesChannelStockLocation
}

// get_variants_availability:
//  1. Gathers all p.product_sales_channels entries where sales_channel_id_bin matches.
//  2. Gathers all p.sales_channel_stock_locations entries where sales_channel_id_bin matches.
//  3. For each v in variants:
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
fn get_variants_availability(p GetProductVariantsAvailabilityParams) map[string]ProductVariantAvailability {
	mut products_in_sales_channels := [][]u8{}
	for i := 0; i < p.product_sales_channels.len; i++ {
		psc := p.product_sales_channels[i]
		if p.sales_channel_ids_bin.contains(psc.sales_channel_id_bin)
			&& !products_in_sales_channels.contains(psc.product_id_bin) {
			products_in_sales_channels = arrays.concat(products_in_sales_channels,
				psc.product_id_bin)
		}
	}

	mut allowed_stock_locations := [][]u8{}
	for i := 0; i < p.sales_channel_stock_locations.len; i++ {
		scsl := p.sales_channel_stock_locations[i]
		if p.sales_channel_ids_bin.contains(scsl.sales_channel_id_bin)
			&& !allowed_stock_locations.contains(scsl.stock_location_id_bin) {
			allowed_stock_locations = arrays.concat(allowed_stock_locations,
				scsl.stock_location_id_bin)
		}
	}

	mut res := map[string]ProductVariantAvailability{}
	for i := 0; i < p.variants.len; i++ {
		variant := p.variants[i]
		if products_in_sales_channels.contains(variant.product_id_bin) {
			res[variant.id] = get_variant_availability(variant, allowed_stock_locations)
		} else {
			res[variant.id] = ProductVariantAvailability{
				purchasable:        false
				inventory_quantity: 0
			}
		}
	}
	return res
}
