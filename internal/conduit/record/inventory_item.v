module record

import arrays
import einar_hjortdal.firebird

pub struct InventoryLevel {
pub:
	inventory_item_id ID
	stock_location_id ID
	stocked_quantity  i32
	reserved_quantity i32
}

pub fn inventory_level_get(mut tx firebird.ClientTransaction, inventory_item_ids []ID) ![]InventoryLevel {
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

		inventory_item_id := id_from_bytes(inventory_item_id_bin)!
		stock_location_id := id_from_bytes(stock_location_id_bin)!

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
	inventory_item_id ID
	stock_location_id ID
	stocked_quantity  i32
}

pub fn inventory_level_update(mut tx firebird.ClientTransaction, p InventoryLevelUpdateParams) ! {
	tx.execute('MERGE INTO inventory_level t
		USING (
			SELECT
				CAST(? AS BINARY(16)) AS inventory_item_id,
				CAST(? AS BINARY(16)) AS stock_location_id,
				CAST(? AS INTEGER) AS stocked_quantity
			FROM RDB\$DATABASE
		) s
		ON t.inventory_item_id = s.inventory_item_id
		AND t.stock_location_id = s.stock_location_id
		WHEN MATCHED THEN 
			UPDATE SET t.stocked_quantity = s.stocked_quantity
		WHEN NOT MATCHED THEN
			INSERT (inventory_item_id, stock_location_id, stocked_quantity)
			VALUES (s.inventory_item_id, s.stock_location_id, s.stocked_quantity)',
		p.inventory_item_id.bytes(), p.stock_location_id.bytes(), p.stocked_quantity)!
}

pub struct InventoryItem {
pub:
	id                ID
	created_at        firebird.DateTime
	updated_at        firebird.DateTime
	deleted_at        ?firebird.DateTime
	variant_id        ID
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
	inventory_levels []InventoryLevel
}

pub fn (ii InventoryItem) id() ID {
	return ii.id
}

// Whenever a variant is created, a related inventory_item is also created.
// A inventory_item may have 0 or more inventory_level.
// When sending a variant response, calculate:
// - inventory_quantity (sum of all sellable iventory_item)
// - purchasable (!manage_inventory || iventory_quantity > 0 || allow_backorder)
// The frontend can assume the variant can be backordered if (inventoryQuantity === 0 && purchasable)

pub fn inventory_item_retrieve(mut tx firebird.ClientTransaction, variant_ids []ID) ![]InventoryItem {
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

		id := id_from_bytes(id_bin)!
		variant_id := id_from_bytes(variant_id_bin)!

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

// TODO fix option types
pub struct InventoryItemCreateParams {
pub:
	id                ID
	variant_id        ID
	sku               string
	origin_country    string
	hs_code           string
	mid_code          string
	material          string
	weight            i32
	length            i32
	height            i32
	width             i32
	requires_shipping bool
	manage_inventory  bool
	allow_backorder   bool
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

		if item.sku != '' {
			params[i * n_params + 2] = item.sku
		}

		if item.origin_country != '' {
			params[i * n_params + 3] = item.origin_country
		}

		if item.hs_code != '' {
			params[i * n_params + 4] = item.hs_code
		}

		if item.mid_code != '' {
			params[i * n_params + 5] = item.mid_code
		}

		if item.material != '' {
			params[i * n_params + 6] = item.material
		}

		if item.weight != 0 {
			params[i * n_params + 7] = item.weight
		}

		if item.length != 0 {
			params[i * n_params + 8] = item.length
		}

		if item.height != 0 {
			params[i * n_params + 9] = item.height
		}

		if item.width != 0 {
			params[i * n_params + 10] = item.width
		}

		params[i * n_params + 11] = item.requires_shipping
		params[i * n_params + 12] = item.manage_inventory
		params[i * n_params + 13] = item.allow_backorder
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
	id                ID
	variant_id        ID
	sku               string
	origin_country    string
	hs_code           string
	mid_code          string
	material          string
	weight            i32
	length            i32
	height            i32
	width             i32
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

		if item.sku != '' {
			params[i * n_params + 2] = item.sku
		}

		if item.origin_country != '' {
			params[i * n_params + 3] = item.origin_country
		}

		if item.hs_code != '' {
			params[i * n_params + 4] = item.hs_code
		}

		if item.mid_code != '' {
			params[i * n_params + 5] = item.mid_code
		}

		if item.material != '' {
			params[i * n_params + 6] = item.material
		}

		if item.weight != 0 {
			params[i * n_params + 7] = item.weight
		}

		if item.length != 0 {
			params[i * n_params + 8] = item.length
		}

		if item.height != 0 {
			params[i * n_params + 9] = item.height
		}

		if item.width != 0 {
			params[i * n_params + 10] = item.width
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

pub fn inventory_item_delete(mut tx firebird.ClientTransaction, inventory_item_id ID) ! {
	tx.execute('UPDATE inventory_item SET deleted_at = CURRENT_TIMESTAMP WHERE id = ?',
		inventory_item_id.bytes())!
}

// used when updating variants within a product update
pub fn inventory_item_sync_delete(mut tx firebird.ClientTransaction, product_id ID) ! {
	tx.execute('MERGE INTO inventory_item t
		USING
			(
				SELECT 
					id AS variant_id,
					deleted_at
				FROM variant
				WHERE product_id = ?
					AND deleted_at IS NOT NULL
			) s
		ON s.variant_id = t.variant_id
		WHEN MATCHED AND t.deleted_at IS NULL THEN UPDATE 
			SET t.deleted_at = s.deleted_at',
		product_id.bytes())!
}
