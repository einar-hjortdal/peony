module peony

import veb

fn conduit_inventory_item_update(mut app App, mut ctx Context, inventory_item_id_bin []u8, p InventoryItemRequest) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	model_inventory_item_update(mut tx, inventory_item_id_bin, p) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not update inventory_item', err.msg())
	}

	tx.commit() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }

	return success(mut ctx)
}

fn conduit_inventory_level_create(mut app App, mut ctx Context, inventory_item_id_bin []u8, stock_location_id_bin []u8,
	p InventoryLevelRequest) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	model_inventory_level_create(mut tx, inventory_item_id_bin, stock_location_id_bin,
		p) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not create inventory_level', err.msg())
	}

	tx.commit() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }

	return success(mut ctx)
}

fn conduit_inventory_level_update(mut app App, mut ctx Context, inventory_item_id_bin []u8, stock_location_id_bin []u8,
	p InventoryLevelRequest) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	model_inventory_level_update(mut tx, inventory_item_id_bin, stock_location_id_bin,
		p) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not create inventory_level', err.msg())
	}

	tx.commit() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }

	return success(mut ctx)
}
