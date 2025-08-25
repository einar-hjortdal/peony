module peony

import arrays
import einar_hjortdal.firebird

struct InventoryLevel {
	inventory_item_id     string
	inventory_item_id_bin []u8
	stock_location_id     string
	stock_location_id_bin []u8
	stocked_quantity      i32
	reserved_quantity     i32
}

fn model_inventory_level_create(mut tx firebird.Transaction, inventory_item_id_bin []u8, stock_location_id_bin []u8,
	p InventoryLevelRequest) ! {
	mut params := [firebird.Value(inventory_item_id_bin), stock_location_id_bin, p.stocked_quantity]

	tx.execute('INSERT INTO inventory_level (inventory_item_id, stock_location_id, stocked_quantity) 
		VALUES(?, ?, ?)',
		...params)!
}

fn model_inventory_level_update(mut tx firebird.Transaction, inventory_item_id_bin []u8, stock_location_id_bin []u8,
	p InventoryLevelRequest) ! {
	tx.execute('UPDATE inventory_level SET stocked_quantity = ? 
			WHERE inventory_item_id = ? AND stock_location_id = ?',
		p.stocked_quantity, inventory_item_id_bin, stock_location_id_bin)!
}

struct InventoryItem {
	id                string
	id_bin            []u8
	created_at        firebird.DateTime
	updated_at        firebird.DateTime
	deleted_at        firebird.NullDateTime
	sku               firebird.NullString
	origin_country    firebird.NullString
	hs_code           firebird.NullString
	mid_code          firebird.NullString
	material          firebird.NullString
	weight            firebird.NullString
	length            firebird.NullString
	height            firebird.NullString
	width             firebird.NullString
	requires_shipping bool
	manage_inventory  bool
	inventory_levels  []InventoryLevel
}

// Whenever a product_variant is created, a related inventory_item is also created.
// A inventory_item may have 0 or more inventory_level.
// When sending a product_variant response, calculate:
// - inventory_quantity (sum of all sellable iventory_item)
// - purchasable (!manage_inventory || iventory_quantity > 0 || allow_backorder)
// The frontend can assume the variant can be backordered if (inventoryQuantity === 0 && purchasable)

fn model_inventory_item_update(mut tx firebird.Transaction, inventory_item_id_bin []u8, p InventoryItemRequest) ! {
	mut columns := []string{}
	mut params := []firebird.Value{}

	if sku := p.sku {
		columns = arrays.concat(columns, 'sku')
		params = arrays.concat(params, sku)
	}

	if origin_country := p.origin_country {
		columns = arrays.concat(columns, 'origin_country')
		params = arrays.concat(params, origin_country)
	}

	if hs_code := p.hs_code {
		columns = arrays.concat(columns, 'hs_code')
		params = arrays.concat(params, hs_code)
	}

	if mid_code := p.mid_code {
		columns = arrays.concat(columns, 'mid_code')
		params = arrays.concat(params, mid_code)
	}

	if material := p.material {
		columns = arrays.concat(columns, 'material')
		params = arrays.concat(params, material)
	}

	if weight := p.weight {
		columns = arrays.concat(columns, 'weight')
		params = arrays.concat(params, weight)
	}

	if length := p.length {
		columns = arrays.concat(columns, 'length')
		params = arrays.concat(params, length)
	}

	if height := p.height {
		columns = arrays.concat(columns, 'height')
		params = arrays.concat(params, height)
	}

	if width := p.width {
		columns = arrays.concat(columns, 'width')
		params = arrays.concat(params, width)
	}

	if requires_shipping := p.requires_shipping {
		columns = arrays.concat(columns, 'requires_shipping')
		params = arrays.concat(params, requires_shipping)
	}

	if manage_inventory := p.manage_inventory {
		columns = arrays.concat(columns, 'manage_inventory')
		params = arrays.concat(params, manage_inventory)
	}

	if allow_backorder := p.allow_backorder {
		columns = arrays.concat(columns, 'allow_backorder')
		params = arrays.concat(params, allow_backorder)
	}

	params = arrays.concat(params, inventory_item_id_bin)

	tx.execute('UPDATE inventory_item ${get_set_columns(columns)} WHERE id = ?', ...params)!
}
