module peony

import veb

fn conduit_inventory_level_update(mut app App, mut ctx Context, inventory_item_id_bin []u8, stock_location_id_bin []u8,
	p InventoryLevelUpdateRequest) veb.Result {
	mp := InventoryLevelUpdateParams{
		inventory_item_id_bin: inventory_item_id_bin
		stock_location_id_bin: stock_location_id_bin
		stocked_quantity:      p.stocked_quantity
	}

	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	model_inventory_level_update(mut tx, mp) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not create inventory_level', err.msg())
		return ctx.handle_error(perr)
	}

	tx.commit() or {
		perr := new_error_internal(error_transaction_rollback, err.msg())
		return ctx.handle_error(perr)
	}

	return success(mut ctx)
}
