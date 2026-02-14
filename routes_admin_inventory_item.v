module peony

import veb
import json

// creates or updates an inventory level
@['/admin/inventory-items/:inventory_item_id/stock-locations/:stock_location_id'; post]
pub fn (mut app App) admin_inventory_level_update(mut ctx Context, inventory_item_id string, stock_location_id string) veb.Result {
	inventory_item_id_bin := id_string_to_bin(inventory_item_id) or {
		perr := new_error_bad_request(error_id_invalid, 'inventory_item_id')
		return ctx.handle_peony_error(perr)
	}

	stock_location_id_bin := id_string_to_bin(stock_location_id) or {
		perr := new_error_bad_request(error_id_invalid, 'stock_location_id')
		return ctx.handle_peony_error(perr)
	}

	p := json.decode(InventoryLevelUpdateRequest, ctx.req.data) or {
		perr := new_error_bad_request('Could not decode InventoryLevelUpdateRequest',
			err.msg())
		return ctx.handle_peony_error(perr)
	}

	return conduit_inventory_level_update(mut app, mut ctx, inventory_item_id_bin, stock_location_id_bin,
		p)
}
