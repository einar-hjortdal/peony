module peony

import veb

fn conduit_inventory_item_create(mut app App, mut ctx Context, variant_id_bin string,
	stock_location_id_bin string, p InventoryItemRequest) veb.Result {
	// TODO
	// insert new inventory_item row
	// associate with stock_location using inventory_level
	// associate with product_variant using product_variant_inventory_item

	return success(mut ctx)
}
