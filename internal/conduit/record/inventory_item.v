module record

import arrays
import einar_hjortdal.firebird
import objects
import internal.common

pub struct InventoryLevel {
pub:
	inventory_item_id common.ID
	stock_location_id common.ID
	stocked_quantity  i32
	reserved_quantity i32
}

pub fn inventory_level_get(
	mut tx firebird.ClientTransaction,
	inventory_item_id common.ID,
	stock_location_id common.ID) !InventoryLevel {
	data := tx.execute('SELECT 
		il.stocked_quantity,
		COALESCE(r.reserved_quantity, 0) as reserved_quantity
		FROM inventory_level il
		LEFT JOIN (
			SELECT item_id, stock_location_id, SUM(amount) AS reserved_quantity
			FROM item_reservation
			WHERE item_id = ? AND stock_location_id = ?
			GROUP BY item_id, stock_location_id
		) r
			ON r.item_id = il.inventory_item_id
  		AND r.stock_location_id = il.stock_location_id
		WHERE il.inventory_item_id = ? and il.stock_location_id = ?',
		inventory_item_id.bytes(), stock_location_id.bytes(), inventory_item_id.bytes(),
		stock_location_id.bytes())!

	rows := data.rows()
	if rows.len == 0 {
		return error('No inventory_level found with inventory_item_id `${inventory_item_id.string()}` and stock_location_id `${stock_location_id}`')
	}

	v := rows[0].values()
	stocked_quantity, _ := v[0].get_i32()!
	reserved_quantity, _ := v[1].get_i32()!

	return InventoryLevel{
		inventory_item_id: inventory_item_id
		stock_location_id: stock_location_id
		stocked_quantity:  stocked_quantity
		reserved_quantity: reserved_quantity
	}
}

pub fn inventory_level_retrieve(mut tx firebird.ClientTransaction, inventory_item_ids []common.ID) ![]InventoryLevel {
	mut params := arrays.concat(ids_values(inventory_item_ids), ...ids_values(inventory_item_ids))

	data := tx.execute('SELECT 
		il.inventory_item_id,
		il.stock_location_id,
		il.stocked_quantity,
		COALESCE(r.reserved_quantity, 0) as reserved_quantity
		FROM inventory_level il
		LEFT JOIN (
			SELECT item_id, stock_location_id, SUM(amount) AS reserved_quantity
			FROM item_reservation
			WHERE item_id IN (${get_placeholders(inventory_item_ids)})
			GROUP BY item_id, stock_location_id
		) r
			ON r.item_id = il.inventory_item_id
  		AND r.stock_location_id = il.stock_location_id
		WHERE il.inventory_item_id IN (${get_placeholders(inventory_item_ids)})',
		...params)!

	rows := data.rows()
	mut inventory_levels := []InventoryLevel{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()
		inventory_item_id_bin, _ := v[0].get_array_u8()!
		stock_location_id_bin, _ := v[1].get_array_u8()!
		stocked_quantity, _ := v[2].get_i32()!
		reserved_quantity, _ := v[3].get_i32()!

		inventory_item_id := common.id_from_bytes(inventory_item_id_bin)!
		stock_location_id := common.id_from_bytes(stock_location_id_bin)!

		inventory_levels[i] = InventoryLevel{
			inventory_item_id: inventory_item_id
			stock_location_id: stock_location_id
			stocked_quantity:  stocked_quantity
			reserved_quantity: reserved_quantity
		}
	}

	return inventory_levels
}

pub struct InventoryLevelUpdateParams {
pub:
	inventory_item_id   common.ID
	stock_location_id   common.ID
	quantity_adjustment i32
}

pub fn inventory_level_update(mut tx firebird.ClientTransaction, p InventoryLevelUpdateParams) ! {
	data := tx.execute('UPDATE inventory_level
			SET stocked_quantity = stocked_quantity + ?
			WHERE inventory_item_id = ?
				AND stock_location_id = ?',
		p.quantity_adjustment, p.inventory_item_id.bytes(), p.stock_location_id.bytes())!

	if data.affected_rows() == 0 {
		tx.execute('INSERT INTO inventory_level (inventory_item_id, stock_location_id, stocked_quantity)
			VALUES (?, ?, ?)',
			p.inventory_item_id.bytes(), p.stock_location_id.bytes(), p.quantity_adjustment)!
	}

	tx.execute('MERGE INTO item_availability t
		USING (
			SELECT scsl.sales_channel_id
			FROM sales_channel_stock_location scsl
			JOIN sales_channel sc
				ON sc.id = scsl.sales_channel_id
			WHERE scsl.stock_location_id = ?
			AND sc.deleted_at IS NULL
			) s
		ON t.item_id = ? AND t.sales_channel_id = s.sales_channel_id
		WHEN MATCHED THEN
			UPDATE SET t.amount = t.amount + ?
		WHEN NOT MATCHED THEN
			INSERT (item_id, sales_channel_id, amount)
			VALUES (?, s.sales_channel_id, ?)',
		p.stock_location_id.bytes(), p.inventory_item_id.bytes(), p.quantity_adjustment,
		p.inventory_item_id.bytes(), p.quantity_adjustment)!
}

pub struct ItemAvailability {
pub:
	item_id          common.ID
	sales_channel_id common.ID
	amount           i32
}

pub fn item_availability_retrieve(mut tx firebird.ClientTransaction, inventory_item_ids []common.ID) ![]ItemAvailability {
	data := tx.execute('SELECT item_id, sales_channel_id, amount
		FROM item_availability
		WHERE item_id IN (${get_placeholders(inventory_item_ids)})',
		...ids_bytes(inventory_item_ids))!

	rows := data.rows()
	mut item_availabilities := []ItemAvailability{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()
		item_id_bin, _ := v[0].get_array_u8()!
		sales_channel_id_bin, _ := v[1].get_array_u8()!
		amount, _ := v[2].get_i32()!

		item_id := common.id_from_bytes(item_id_bin)!
		sales_channel_id := common.id_from_bytes(sales_channel_id_bin)!

		item_availabilities[i] = ItemAvailability{
			item_id:          item_id
			sales_channel_id: sales_channel_id
			amount:           amount
		}
	}

	return item_availabilities
}

pub struct InventoryItem {
pub:
	id                common.ID
	created_at        firebird.DateTime
	updated_at        firebird.DateTime
	deleted_at        ?firebird.DateTime
	variant_id        common.ID
	sku               ?string
	origin_country    ?string
	hs_code           ?string
	mid_code          ?string
	material          ?string
	weight            ?i32
	length            ?i32
	height            ?i32
	width             ?i32
	requires_shipping bool
	manage_inventory  bool
	allow_backorder   bool
pub mut:
	availability     []ItemAvailability // TODO could be none?
	inventory_levels []InventoryLevel   // TODO could be none
}

pub fn (ii InventoryItem) id() common.ID {
	return ii.id
}

// Whenever a variant is created, a related inventory_item is also created.
// A inventory_item may be stored in 0 or more stock_location.
// The amount of items in each stock_location is an inventory_level.
// Each stock location may serve 0 or more sales_channel.
// item_availability tracks the amount of stocked items available to each sales_channel.
pub fn inventory_item_retrieve(mut tx firebird.ClientTransaction, variant_ids []common.ID) ![]InventoryItem {
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
		WHERE variant_id IN (${get_placeholders(variant_ids)})',
		...ids_bytes(variant_ids))!

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

		id := common.id_from_bytes(id_bin)!
		variant_id := common.id_from_bytes(variant_id_bin)!

		inventory_items[i] = InventoryItem{
			id:                id
			created_at:        created_at
			updated_at:        updated_at
			deleted_at:        deleted_at.none_value()
			variant_id:        variant_id
			sku:               sku.none_value()
			origin_country:    origin_country.none_value()
			hs_code:           hs_code.none_value()
			mid_code:          mid_code.none_value()
			material:          material.none_value()
			weight:            weight.none_value()
			length:            length.none_value()
			height:            height.none_value()
			width:             width.none_value()
			requires_shipping: requires_shipping
			manage_inventory:  manage_inventory
			allow_backorder:   allow_backorder
		}
	}

	return inventory_items
}

pub struct InventoryItemCreateParams {
pub:
	id                common.ID
	variant_id        common.ID
	sku               ?string
	origin_country    ?string
	hs_code           ?string
	mid_code          ?string
	material          ?string
	weight            ?i32
	length            ?i32
	height            ?i32
	width             ?i32
	requires_shipping ?bool
	manage_inventory  ?bool
	allow_backorder   ?bool
}

// TODO validate params
pub fn inventory_item_create(mut tx firebird.ClientTransaction, p []InventoryItemCreateParams) ! {
	mut src := []string{len: p.len}
	n_params := 14
	mut params := []firebird.Value{len: p.len * n_params, init: firebird.Null{}}

	for i := 0; i < p.len; i++ {
		item := p[i]
		src[i] = 'SELECT
			CAST(? AS BINARY(16)) AS id,
			CAST(? AS BINARY(16)) AS variant_id,
			CAST(? AS VARCHAR(63)) AS sku,
			CAST(? AS CHAR(2)) AS origin_country,
			CAST(? AS VARCHAR(63)) AS hs_code,
			CAST(? AS VARCHAR(15)) AS mid_code,
			CAST(? AS VARCHAR(191)) AS material,
			CAST(? AS INTEGER) AS weight,
			CAST(? AS INTEGER) AS length,
			CAST(? AS INTEGER) AS height,
			CAST(? AS INTEGER) AS width,
			CAST(? AS BOOLEAN) AS requires_shipping,
			CAST(? AS BOOLEAN) AS manage_inventory,
			CAST(? AS BOOLEAN) AS allow_backorder
			FROM RDB\$DATABASE'

		params[i * n_params] = item.id.bytes()
		params[i * n_params + 1] = item.variant_id.bytes()

		if sku := item.sku {
			if sku != '' {
				params[i * n_params + 2] = sku
			}
		}

		if origin_country := item.origin_country {
			if origin_country != '' {
				params[i * n_params + 3] = origin_country
			}
		}

		if hs_code := item.hs_code {
			if hs_code != '' {
				params[i * n_params + 4] = hs_code
			}
		}

		if mid_code := item.mid_code {
			if mid_code != '' {
				params[i * n_params + 5] = mid_code
			}
		}

		if material := item.material {
			if material != '' {
				params[i * n_params + 6] = material
			}
		}

		if weight := item.weight {
			if weight != 0 {
				params[i * n_params + 7] = weight
			}
		}

		if length := item.length {
			if length != 0 {
				params[i * n_params + 8] = length
			}
		}

		if height := item.height {
			if height != 0 {
				params[i * n_params + 9] = height
			}
		}

		if width := item.width {
			if width != 0 {
				params[i * n_params + 10] = width
			}
		}

		if requires_shipping := item.requires_shipping {
			params[i * n_params + 11] = requires_shipping
		} else {
			params[i * n_params + 11] = objects.inventory_item_requires_shipping_default
		}

		if manage_inventory := item.manage_inventory {
			params[i * n_params + 12] = manage_inventory
		} else {
			params[i * n_params + 12] = objects.inventory_item_manage_inventory_default
		}

		if allow_backorder := item.allow_backorder {
			params[i * n_params + 13] = allow_backorder
		} else {
			params[i * n_params + 13] = objects.inventory_item_allow_backorder_default
		}
	}

	tx.execute('INSERT INTO inventory_item
		(
			id,
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
		)
		${get_merge_source(src)}',
		...params)!
}

pub struct InventoryItemUpdateParams {
pub:
	id                common.ID
	variant_id        common.ID
	sku               ?string
	origin_country    ?string
	hs_code           ?string
	mid_code          ?string
	material          ?string
	weight            ?i32
	length            ?i32
	height            ?i32
	width             ?i32
	requires_shipping bool
	manage_inventory  bool
	allow_backorder   bool
}

pub fn inventory_item_update(mut tx firebird.ClientTransaction, p []InventoryItemUpdateParams) ! {
	mut src := []string{len: p.len}
	n_params := 14
	mut params := []firebird.Value{len: p.len * n_params, init: firebird.Null{}}
	for i := 0; i < p.len; i++ {
		item := p[i]
		src[i] = 'SELECT
			CAST(? AS BINARY(16)) AS id,
			CAST(? AS BINARY(16)) AS variant_id,
			CAST(? AS VARCHAR(63)) AS sku,
			CAST(? AS CHAR(2)) AS origin_country,
			CAST(? AS VARCHAR(63)) AS hs_code,
			CAST(? AS VARCHAR(15)) AS mid_code,
			CAST(? AS VARCHAR(191)) AS material,
			CAST(? AS INTEGER) AS weight,
			CAST(? AS INTEGER) AS length,
			CAST(? AS INTEGER) AS height,
			CAST(? AS INTEGER) AS width,
			CAST(? AS BOOLEAN) AS requires_shipping,
			CAST(? AS BOOLEAN) AS manage_inventory,
			CAST(? AS BOOLEAN) AS allow_backorder
			FROM RDB\$DATABASE'

		params[i * n_params + 0] = item.id.bytes()
		params[i * n_params + 1] = item.variant_id.bytes()

		if sku := item.sku {
			if sku != '' {
				params[i * n_params + 2] = sku
			}
		}

		if origin_country := item.origin_country {
			if origin_country != '' {
				params[i * n_params + 3] = origin_country
			}
		}

		if hs_code := item.hs_code {
			if hs_code != '' {
				params[i * n_params + 4] = hs_code
			}
		}

		if mid_code := item.mid_code {
			if mid_code != '' {
				params[i * n_params + 5] = mid_code
			}
		}

		if material := item.material {
			if material != '' {
				params[i * n_params + 6] = material
			}
		}

		if weight := item.weight {
			if weight != 0 {
				params[i * n_params + 7] = weight
			}
		}

		if length := item.length {
			if length != 0 {
				params[i * n_params + 8] = length
			}
		}

		if height := item.height {
			if height != 0 {
				params[i * n_params + 9] = height
			}
		}

		if width := item.width {
			if width != 0 {
				params[i * n_params + 10] = width
			}
		}

		params[i * n_params + 11] = item.requires_shipping
		params[i * n_params + 12] = item.manage_inventory
		params[i * n_params + 13] = item.allow_backorder
	}

	query := 'MERGE INTO inventory_item t
		USING (${get_merge_source(src)}) s
		ON s.id = t.id
		WHEN MATCHED THEN UPDATE
			SET
				t.updated_at = CURRENT_TIMESTAMP,
				t.sku = s.sku,
				t.origin_country = s.origin_country,
				t.hs_code = s.hs_code,
				t.mid_code = s.mid_code,
				t.material = s.material,
				t.weight = s.weight,
				t.length = s.length,
				t.height = s.height,
				t.width = s.width,
				t.requires_shipping = s.requires_shipping,
				t.manage_inventory = s.manage_inventory,
				t.allow_backorder = s.allow_backorder
		WHEN NOT MATCHED THEN
			INSERT
				(
					id,
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
				)
			VALUES
				(
					s.id,
					s.variant_id,
					s.sku,
					s.origin_country,
					s.hs_code,
					s.mid_code,
					s.material,
					s.weight,
					s.length,
					s.height,
					s.width,
					s.requires_shipping,
					s.manage_inventory,
					s.allow_backorder
				)
			'

	tx.execute(query, ...params)!
}

pub fn inventory_item_delete(mut tx firebird.ClientTransaction, inventory_item_id common.ID) ! {
	tx.execute('UPDATE inventory_item SET deleted_at = CURRENT_TIMESTAMP WHERE id = ?',
		inventory_item_id.bytes())!
}
