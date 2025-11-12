module peony

import veb
import json

// creates or updates an inventory level
@['/admin/inventory-items/:inventory_item_id/stock-locations/:stock_location_id'; post]
pub fn (mut app App) admin_inventory_level_update(mut ctx Context, inventory_item_id string, stock_location_id string) veb.Result {
	inventory_item_id_bin := id_string_to_bin(inventory_item_id) or {
		return handle_error_400(mut ctx, error_id_invalid, 'inventory_item_id')
	}

	stock_location_id_bin := id_string_to_bin(stock_location_id) or {
		return handle_error_400(mut ctx, error_id_invalid, 'stock_location_id')
	}

	p := json.decode(InventoryLevelUpdateRequest, ctx.req.data) or {
		return handle_error_400(mut ctx, 'Could not decode InventoryLevelUpdateRequest',
			err.msg())
	}

	// TODO validate new stocked_quantity is not less than reserved_quantity

	return conduit_inventory_level_update(mut app, mut ctx, inventory_item_id_bin, stock_location_id_bin,
		p)
}
