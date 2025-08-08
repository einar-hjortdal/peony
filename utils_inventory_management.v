module peony

// WIP

// Returns calculated purchasable and inventory_quantity values
// A variant is purchasable if:
// - manage_inventory is false
// - allow_backorder is true
// - it has no inventory items (TODO)
// - no sales_channel is provided
// - inventory_quantity > 0
fn get_variant_availability(v Variant, sales_channel_id_bin []u8) (bool, i32) {
	if !v.manage_inventory {
		return true, 0
	}

	if sales_channel_id_bin.len == 0 {
		return false, 0
	}

	// why is it like this?
	// inventory_items := TODO get inventory items
	// if inventory_items.len == 0 {
	// 	return true, 0
	// }

	// for
	available_quantity := i32(0) // TODO sum of all inventory items - reserved items
	if available_quantity == 0 {
		if v.allow_backorder {
			return true, 0
		}
		return false, 0
	}

	return true, available_quantity
}

// for each variant:
// 1) retrieve product_variant_inventory_item
// 2) calculate available quantity of each variant in the stock locations related to the sales channel
// 3) for each inventory_item calculate the maximum deliverable amount according to required_quantity of product_variant_inventory_item
// 4) the smallest number of these maximum deliverable amounts is the availability for this variant
fn get_variants_availability(v []Variant, sales_channel_id_bin []u8) ([]bool, []i32) {
	return []bool{}, []i32{}
}
