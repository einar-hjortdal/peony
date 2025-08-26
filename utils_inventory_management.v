module peony

// WIP
// `product_variant` has a manage_inventory bool that indicates whether peony  manages the inventory.
// When manage_inventory is false, peony always considers the product_variant to be in stock.
// When manage_inventory is true, peony tracks the inventory of the product_variant. For example, when
// a customer purchases a product_variant, peony decrements the stocked quantity of the product_variant.

fn get_variant_availability(v ProductVariant, sales_channel_id_bin []u8) i32 {
	// if !v.manage_inventory {
	// 	return 0
	// }

	// if sales_channel_id_bin.len == 0 {
	// 	return 0
	// }

	// why is it like this?
	// inventory_items := TODO get all inventory_item or have them inside of Variant already
	// if inventory_items.len == 0 {
	// 	return true, 0
	// }

	// for
	available_quantity := i32(0) // TODO sum of all inventory items - reserved items
	// if available_quantity == 0 {
	// 	if v.allow_backorder {
	// 		return 0
	// 	}
	// 	return 0
	// }

	return available_quantity
}

// for each variant:
// 1) retrieve product_variant_inventory_item
// 2) calculate available quantity of each variant in the stock locations related to the sales channel
// 3) for each inventory_item calculate the maximum deliverable amount according to required_quantity of product_variant_inventory_item
// 4) the smallest number of these maximum deliverable amounts is the availability for this variant
fn get_variants_availability(v []ProductVariant, sales_channel_id_bin []u8) []i32 {
	return []i32{}
}
