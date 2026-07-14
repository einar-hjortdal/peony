module peony

import veb
import einar_hjortdal.firebird
import internal.conduit
import internal.errors
import internal.common

// creates or updates an inventory level
@['/admin/inventory-items/:inventory_item_id/stock-locations/:stock_location_id'; post]
pub fn (mut app App) admin_inventory_level_update(mut ctx Context, inventory_item_id string, stock_location_id string) veb.Result {
	parsed_inventory_item_id := common.id_from_string(inventory_item_id) or {
		return ctx.handle_error(errors.bad_request(errors.id_invalid, 'inventory_item_id'))
	}

	parsed_stock_location_id := common.id_from_string(stock_location_id) or {
		return ctx.handle_error(errors.bad_request(errors.id_invalid, 'stock_location_id'))
	}

	p := hygienise_inventory_level_update_request(ctx.req.data, parsed_inventory_item_id,
		parsed_stock_location_id) or { return ctx.handle_error(err) }

	inventory_level := app.with_commit(fn [p] (mut tx firebird.ClientTransaction) !conduit.InventoryLevel {
		conduit.inventory_level_update(mut tx, p)!
		return conduit.inventory_level_get(mut tx, p.inventory_item_id, p.stock_location_id)
	}) or { return ctx.handle_error(err) }

	return ctx.handle_ok(InventoryLevelResponseEnvelope{
		inventory_level: format_inventory_level_response(inventory_level)
	})
}
