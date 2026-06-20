module conduit

import arrays
import einar_hjortdal.firebird
import record
import internal.errors

// TODO return specific inventory_level, requires refactor of record fn
pub fn inventory_level_get(mut tx firebird.ClientTransaction, inventory_item_id ID, stock_location_id ID) !InventoryLevel {
	inventory_level := record.inventory_level_get(mut tx, inventory_item_id, stock_location_id) or {
		return errors.internal('Failed to retrieve stock inventory_level', err.msg())
	}
	return inventory_level
}

pub struct InventoryLevelUpdateParams {
pub:
	inventory_item_id ID
	stock_location_id ID
	stocked_quantity  i32
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
		inventory_item_id: p.inventory_item_id
		stock_location_id: p.stock_location_id
		stocked_quantity:  p.stocked_quantity
	}
}

pub fn inventory_level_update(mut tx firebird.ClientTransaction, p InventoryLevelUpdateParams) ! {
	p.check(mut tx)!
	data := p.parse()
	record.inventory_level_update(mut tx, data) or {
		return errors.internal('Could not create inventory_level', err.msg())
	}
}

fn get_inventory_items_levels(mut tx firebird.ClientTransaction, mut items_map map[string]record.InventoryItem, items_ids []ID) ! {
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
