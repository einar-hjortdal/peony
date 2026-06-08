module conduit

import einar_hjortdal.firebird
import record
import arrays

pub type InventoryItem = record.InventoryItem
pub type InventoryLevel = record.InventoryLevel

pub fn inventory_level_update(mut tx firebird.Transaction, p record.InventoryLevelUpdateParams) ! {
	record.inventory_level_update(mut tx, p) or {
		return new_error_internal('Could not create inventory_level', err.msg())
	}
}

fn get_inventory_items_levels(mut tx firebird.Transaction, mut items_map map[string]record.InventoryItem, items_ids []ID) ! {
	inventory_levels := record.inventory_level_get(mut tx, items_ids) or {
		return new_error_internal('Failed to retrieve inventory_level', err.msg())
	}

	for i := 0; i < inventory_levels.len; i++ {
		level := inventory_levels[i]
		item_id := inventory_levels[i].inventory_item_id
		old := items_map[item_id.string()].inventory_levels
		items_map[item_id.string()].inventory_levels = arrays.concat(old, level)
	}
}
