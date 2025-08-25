module peony

import veb
import json

// Updates an inventory_item
@['/admin/inventory-items/:inventory_item_id'; post]
pub fn (mut app App) admin_inventory_item_iventory_levels_get(mut ctx Context, inventory_item_id string) veb.Result {
	inventory_item_id_bin := id_string_to_bin(inventory_item_id) or {
		return handle_error_400(mut ctx, error_id_invalid, 'inventory_item_id')
	}

	p := json.decode(InventoryItemRequest, ctx.req.data) or {
		return handle_error_400(mut ctx, 'Could not decode InventoryItemRequest', err.msg())
	}

	if p.sku == none && p.origin_country == none && p.hs_code == none && p.mid_code == none
		&& p.material == none && p.weight == none && p.length == none && p.height == none
		&& p.width == none && p.manage_inventory == none && p.requires_shipping == none {
		return handle_error_400(mut ctx, error_empty_object, 'InventoryItemRequest')
	}

	return conduit_inventory_item_update(mut app, mut ctx, inventory_item_id_bin, p)
}

// creates an inventory_level for an inventory_item at the stock_location
@['/admin/inventory-items/:inventory_item_id/stock-locations/:stock_location_id'; post]
pub fn (mut app App) admin_variant_inventory_level_create(mut ctx Context, inventory_item_id string, stock_location_id string) veb.Result {
	inventory_item_id_bin := id_string_to_bin(inventory_item_id) or {
		return handle_error_400(mut ctx, error_id_invalid, 'inventory_item_id')
	}

	stock_location_id_bin := id_string_to_bin(stock_location_id) or {
		return handle_error_400(mut ctx, error_id_invalid, 'stock_location_id')
	}

	p := json.decode(InventoryLevelRequest, ctx.req.data) or {
		return handle_error_400(mut ctx, 'Could not decode InventoryLevelRequest', err.msg())
	}

	return conduit_inventory_level_create(mut app, mut ctx, inventory_item_id_bin, stock_location_id_bin,
		p)
}

// updates an inventory level
@['/admin/inventory-items/:inventory_item_id/stock-locations/:stock_location_id'; post]
pub fn (mut app App) admin_inventory_items_inventory_level_update(mut ctx Context, inventory_item_id string, stock_location_id string) veb.Result {
	inventory_item_id_bin := id_string_to_bin(inventory_item_id) or {
		return handle_error_400(mut ctx, error_id_invalid, 'inventory_item_id')
	}

	stock_location_id_bin := id_string_to_bin(stock_location_id) or {
		return handle_error_400(mut ctx, error_id_invalid, 'stock_location_id')
	}

	p := json.decode(InventoryLevelRequest, ctx.req.data) or {
		return handle_error_400(mut ctx, 'Could not decode InventoryLevelRequest', err.msg())
	}

	// TODO validate new stocked_quantity is not less than reserved_quantity

	return conduit_inventory_level_update(mut app, mut ctx, inventory_item_id_bin, stock_location_id_bin,
		p)
}
