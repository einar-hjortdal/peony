module peony

struct ProductVariantAvailability {
	purchasable        bool
	available_quantity i32
}

// returns whether the product_variant is purchasable and its available amount.
// if inventory is not managed by peony, the product_variant is always available.
fn get_product_variant_availability(v ProductVariant, additional_var ToDecideType) ProductVariantAvailability {
	inventory_item := v.inventory_item
	if !inventory_item.manage_inventory {
		return ProductVariantAvailability{
			purchasable:        true
			available_quantity: 0
		}
	}

	// TODO only consider stock_location related to the sales_channel requested
	// To do that we need:
	// the parent product's sales_channels property
	// the sales_channel_stock_location relation
	// 1) check if sales_channel_id is in the product.sales_channels list
	// 2) if it is, get the stock_locations list for that sales_channel. If it isn't, availability is 0
	// 3) if sales_channel stock_location use these ids when continuing execution. Otherwise availability is 0.

	inventory_levels := inventory_item.inventory_levels
	if inventory_levels.len == 0 {
		return ProductVariantAvailability{
			purchasable:        false
			available_quantity: 0
		}
	}

	mut available_quantity := i32(0) // TODO sum of all inventory items - reserved items
	for i := 0; i < inventory_levels.len; i++ {
		inventory_level := inventory_levels[i]
		available_quantity += (inventory_level.stocked_quantity - inventory_level.reserved_quantity)
	}

	if available_quantity == 0 {
		if inventory_item.allow_backorder {
			return ProductVariantAvailability{
				purchasable:        true
				available_quantity: 0
			}
		}
		return ProductVariantAvailability{
			purchasable:        false
			available_quantity: 0
		}
	}

	return ProductVariantAvailability{
		purchasable:        true
		available_quantity: available_quantity
	}
}

struct GetProductVariantsAvailabilityParams {
	product_sales_channels        []ProductSalesChannel
	sales_channel_stock_locations []SalesChannelStockLocation
}

// returns a mapping of product_variant id to its availability
fn get_product_variants_availability(product_variants []ProductVariant,
	sales_channel_id string, p GetProductVariantsAvailabilityParams) map[string]ProductVariantAvailability {
	// what needs to be done:
	// product_variant.product_id -> product_sales_channels.product_id
	// product_sales_channels.product_id -> product_sales_channels.sales_channel_id
	// sales_channel.id -> sales_channel_stock_locations.sales_channel_id
	// sales_channel_stock_locations.stock_location_id -> product_variant.inventory_item.inventory_level.stock_location_id

	mut allowed_stock_locations := map[string]bool{}
	for i := 0; i < p.sales_channel_stock_locations.len; i++ {
		scsl := p.sales_channel_stock_locations[i]
		if scsl.sales_channel_id == sales_channel_id {
			allowed_stock_locations[scsl.stock_location_id] = true
		}
	}

	mut res := map[string]ProductVariantAvailability{}

	for i := 0; i < product_variants.len; i++ {
		v := product_variants[i]
		availability := get_product_variant_availability(v, additional_var)
		res[v.id] = availability
	}
	return res
}
