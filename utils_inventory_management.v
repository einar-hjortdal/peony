module peony

// returns whether the product_variant is purchasable and its available amount.
// if inventory is not managed by peony, the product_variant is always available.
fn get_variant_availability(v ProductVariant) (bool, i32) {
	inventory_item := v.inventory_item
	if !inventory_item.manage_inventory {
		return true, 0
	}

	// TODO only consider stock_location related to the sales_channel requested
	// if sales_channel_id_bin.len == 0 {
	// 	return false, 0
	// }

	inventory_levels := inventory_item.inventory_levels
	if inventory_levels.len == 0 {
		return false, 0
	}

	mut available_quantity := i32(0) // TODO sum of all inventory items - reserved items
	for i := 0; i < inventory_levels.len; i++ {
		inventory_level := inventory_levels[i]
		available_quantity += (inventory_level.stocked_quantity - inventory_level.reserved_quantity)
	}

	if available_quantity == 0 {
		if inventory_item.allow_backorder {
			return true, 0
		}
		return false, 0
	}

	return true, available_quantity
}
