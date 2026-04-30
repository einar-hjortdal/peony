module conduit

import einar_hjortdal.firebird
import record

pub type InventoryItem = record.InventoryItem

pub type InventoryItemCreateParams = record.InventoryItemCreateParams

pub type InventoryItemUpdateParams = record.InventoryItemUpdateParams

pub type InventoryLevel = record.InventoryLevel

pub type InventoryLevelUpdateParams = record.InventoryLevelUpdateParams

pub fn inventory_level_update(mut tx firebird.Transaction, p InventoryLevelUpdateParams) ! {
	record.inventory_level_update(mut tx, p) or {
		return new_error_internal('Could not create inventory_level', err.msg())
	}
}

