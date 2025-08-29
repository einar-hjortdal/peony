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

fn model_inventory_level_get(mut tx firebird.Transaction, inventory_item_ids_bin [][]u8) ![]InventoryLevel {
	data := tx.execute('SELECT inventory_item_id, stock_location_id, stocked_quantity, reserved_quantity
		FROM inventory_level WHERE inventory_item_id IN (${get_placeholders(inventory_item_ids_bin)})',
		...workaround_24757(inventory_item_ids_bin))!

	rows := data.rows()
	mut inventory_levels := []InventoryLevel{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()
		inventory_item_id_bin, _ := v[0].get_array_u8()!
		stock_location_id_bin, _ := v[1].get_array_u8()!
		stocked_quantity, _ := v[2].get_i32()!
		reserved_quantity, _ := v[3].get_i32()!

		inventory_item_id := id_bin_to_string(inventory_item_id_bin)!
		stock_location_id := id_bin_to_string(stock_location_id_bin)!

		inventory_levels[i] = InventoryLevel{
			inventory_item_id:     inventory_item_id
			inventory_item_id_bin: inventory_item_id_bin
			stock_location_id:     stock_location_id
			stock_location_id_bin: stock_location_id_bin
			stocked_quantity:      stocked_quantity
			reserved_quantity:     reserved_quantity
		}
	}

	return inventory_levels
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
	variant_id        string
	variant_id_bin    []u8
	sku               firebird.NullString
	origin_country    firebird.NullString
	hs_code           firebird.NullString
	mid_code          firebird.NullString
	material          firebird.NullString
	weight            firebird.NullI32
	length            firebird.NullI32
	height            firebird.NullI32
	width             firebird.NullI32
	requires_shipping bool
	manage_inventory  bool
	allow_backorder   bool
mut:
	inventory_levels []InventoryLevel
}

// Whenever a product_variant is created, a related inventory_item is also created.
// A inventory_item may have 0 or more inventory_level.
// When sending a product_variant response, calculate:
// - inventory_quantity (sum of all sellable iventory_item)
// - purchasable (!manage_inventory || iventory_quantity > 0 || allow_backorder)
// The frontend can assume the variant can be backordered if (inventoryQuantity === 0 && purchasable)

fn model_inventory_item_retrieve(mut tx firebird.Transaction, product_variant_ids_bin [][]u8) ![]InventoryItem {
	data := tx.execute('SELECT
		id,
		created_at,
		updated_at,
		deleted_at,
		variant_id,
		sku,
		origin_country,
		hs_code,
		mid_code,
		material,
		weight,
		length,
		height,
		width,
		requires_shipping,
		manage_inventory,
		allow_backorder
		FROM inventory_item
		WHERE variant_id IN (${get_placeholders(product_variant_ids_bin)})',
		...workaround_24757(product_variant_ids_bin))!

	rows := data.rows()
	mut inventory_items := []InventoryItem{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()
		id_bin, _ := v[0].get_array_u8()!
		created_at, _ := v[1].get_date_time()!
		updated_at, _ := v[2].get_date_time()!
		deleted_at := v[3].get_null_date_time()!
		variant_id_bin, _ := v[4].get_array_u8()!
		sku := v[5].get_null_string()!
		origin_country := v[6].get_null_string()!
		hs_code := v[7].get_null_string()!
		mid_code := v[8].get_null_string()!
		material := v[9].get_null_string()!
		weight := v[10].get_null_i32()!
		length := v[11].get_null_i32()!
		height := v[12].get_null_i32()!
		width := v[13].get_null_i32()!
		requires_shipping, _ := v[14].get_bool()!
		manage_inventory, _ := v[15].get_bool()!
		allow_backorder, _ := v[16].get_bool()!

		id := id_bin_to_string(id_bin)!
		variant_id := id_bin_to_string(variant_id_bin)!

		inventory_items[i] = InventoryItem{
			id:                id
			id_bin:            id_bin
			created_at:        created_at
			updated_at:        updated_at
			deleted_at:        deleted_at
			variant_id:        variant_id
			variant_id_bin:    variant_id_bin
			sku:               sku
			origin_country:    origin_country
			hs_code:           hs_code
			mid_code:          mid_code
			material:          material
			weight:            weight
			length:            length
			height:            height
			width:             width
			requires_shipping: requires_shipping
			manage_inventory:  manage_inventory
			allow_backorder:   allow_backorder
		}
	}

	return inventory_items
}

fn model_inventory_item_create(mut tx firebird.Transaction, inventory_item_id_bin []u8, variant_id_bin []u8) ! {
	tx.execute('INSERT INTO inventory_item (id, variant_id) VALUES (?, ?)', inventory_item_id_bin,
		variant_id_bin)!
}

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

fn model_inventory_item_delete(mut tx firebird.Transaction, inventory_item_id_bin []u8) ! {
	tx.execute('UPDATE inventory_item SET deleted_at = CURRENT_TIMESTAMP WHERE id = ?',
		inventory_item_id_bin)!
}
