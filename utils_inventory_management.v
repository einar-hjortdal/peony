module peony

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

struct VariantAvailability {
	purchasable      bool
	amount_available i32
}

fn new_variant_availability(purchasable bool, amount_available i32) VariantAvailability {
	return VariantAvailability{
		purchasable:      purchasable
		amount_available: amount_available
	}
}

// used by store endpoints
fn get_variant_availability(v conduit.Variant, sales_channel_id ID) VariantAvailability {
	if !v.inventory_item.manage_inventory {
		return VariantAvailability{
			purchasable:      true
			amount_available: 0
		}
	}

	allow_backorder := v.inventory_item.allow_backorder
	ias := v.inventory_item.availability
	for i := 0; i < ias.len; i++ {
		ia := ias[i]
		if ia.sales_channel_id.string() == sales_channel_id.string() { // there is stock
			if ia.amount < 1 && !allow_backorder {
				return new_variant_availability(false, ia.amount)
			}
			return new_variant_availability(true, ia.amount)
		}
	}
	// variant not in stock in any stock location related to this sales channel
	if allow_backorder {
		return new_variant_availability(true, 0)
	}
	return new_variant_availability(false, 0)
}
