module conduit

import arrays
import einar_hjortdal.firebird
import record
import internal.errors
import internal.common

pub fn inventory_level_get(mut tx firebird.ClientTransaction, inventory_item_id common.ID, stock_location_id common.ID) !InventoryLevel {
	inventory_level := record.inventory_level_get(mut tx, inventory_item_id, stock_location_id) or {
		return errors.internal('Failed to retrieve stock inventory_level', err.msg())
	}
	return inventory_level
}

pub struct InventoryLevelUpdateParams {
pub:
	inventory_item_id   common.ID
	stock_location_id   common.ID
	quantity_adjustment i32
}

fn (p InventoryLevelUpdateParams) check(mut tx firebird.ClientTransaction) ! {
	// TODO check inventory_item_id exist
	stock_location_count := record.stock_location_retrieve_count(mut tx, record.StockLocationRetrieveParams{
		ids: [p.stock_location_id]
	}) or { return errors.internal('Failed to retrieve stock_location count', err.msg()) }

	if stock_location_count == 0 {
		return errors.internal('No stock_location exists with id ${p.stock_location_id.string()}',
			'stock_location_count == 0')
	}
}

fn (p InventoryLevelUpdateParams) parse() record.InventoryLevelUpdateParams {
	return record.InventoryLevelUpdateParams{
		inventory_item_id:   p.inventory_item_id
		stock_location_id:   p.stock_location_id
		quantity_adjustment: p.quantity_adjustment
	}
}

pub fn inventory_level_update(mut tx firebird.ClientTransaction, p InventoryLevelUpdateParams) ! {
	p.check(mut tx)!
	data := p.parse()
	record.inventory_level_update(mut tx, data) or {
		return errors.internal('Could not create inventory_level', err.msg())
	}
}

fn get_inventory_items_levels(mut tx firebird.ClientTransaction, mut items_map map[string]record.InventoryItem, items_ids []common.ID) ! {
	inventory_levels := record.inventory_level_retrieve(mut tx, items_ids) or {
		return errors.internal('Failed to retrieve inventory_level', err.msg())
	}

	for i := 0; i < inventory_levels.len; i++ {
		level := inventory_levels[i]
		item_id := inventory_levels[i].inventory_item_id
		old := items_map[item_id.string()].inventory_levels
		items_map[item_id.string()].inventory_levels = arrays.concat(old, level)
	}
}

fn get_item_availability(mut tx firebird.ClientTransaction, mut items_map map[string]record.InventoryItem, items_ids []common.ID) ! {
	item_availabilities := record.item_availability_retrieve(mut tx, items_ids) or {
		return errors.internal('Failed to retrieve item_availability', err.msg())
	}

	for i := 0; i < item_availabilities.len; i++ {
		availability := item_availabilities[i]
		item_id := availability.item_id
		old := items_map[item_id.string()].availability
		items_map[item_id.string()].availability = arrays.concat(old, availability)
	}
}
