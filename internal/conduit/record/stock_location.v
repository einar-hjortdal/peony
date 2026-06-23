module record

import arrays
import einar_hjortdal.firebird

pub struct StockLocation {
pub:
	id         ID
	created_at firebird.DateTime
	updated_at firebird.DateTime
	deleted_at ?firebird.DateTime
	name       string
	// address Address
	// sales_channels []SalesChannel
}

pub fn (sl StockLocation) id() ID {
	return sl.id
}

pub struct StockLocationCreateParams {
pub:
	id   ID
	name string
	// address
}

pub fn stock_location_create(mut tx firebird.ClientTransaction, p StockLocationCreateParams) ! {
	tx.execute('INSERT INTO stock_location (id, name) VALUES (?, ?)', p.id.bytes(), p.name)!
}

pub struct StockLocationUpdateParams {
pub:
	id   ID
	name string
	// address
}

pub fn stock_location_update(mut tx firebird.ClientTransaction, p StockLocationUpdateParams) ! {
	c := ['name']
	params := [firebird.Value(p.name), p.id.bytes()]
	tx.execute('UPDATE stock_location SET ${get_set_columns_with_updated_at(c)} WHERE id = ?',
		...params)!
}

pub struct StockLocationRetrieveParams {
pub:
	ids          ?[]ID
	with_deleted bool
	offset       i32
	fetch        i32
	order        string
}

fn stock_location_retrieve_conditions(p StockLocationRetrieveParams) (string, []firebird.Value) {
	mut conditions := []string{}
	mut params := []firebird.Value{}

	if ids := p.ids {
		conditions = arrays.concat(conditions, 'id IN (${get_placeholders(ids)})')
		params = arrays.concat(params, ...ids_bytes(ids))
	}

	if !p.with_deleted {
		conditions = arrays.concat(conditions, 'deleted_at IS NULL')
	}

	return get_where_conditions(conditions), params
}

pub fn stock_location_retrieve_count(mut tx firebird.ClientTransaction, p StockLocationRetrieveParams) !i64 {
	conditions, params := stock_location_retrieve_conditions(p)
	data := tx.execute('SELECT COUNT(*) FROM stock_location ${conditions}', ...params)!
	rows := data.rows()
	values := rows[0].values() // should always return one row
	count, _ := values[0].get_i64()! // should always return one column
	return count
}

pub fn stock_location_retrieve(mut tx firebird.ClientTransaction, p StockLocationRetrieveParams) ![]StockLocation {
	conditions, mut params := stock_location_retrieve_conditions(p)

	mut sorting := 'ORDER BY created_at ${p.order}
		OFFSET ? ROWS
		FETCH NEXT ? ROWS ONLY'
	params = arrays.concat(params, p.offset, p.fetch)

	query := 'SELECT
		id,
		created_at,
		updated_at,
		deleted_at,
		name,
		address_id
		FROM stock_location
		${conditions}
		${sorting}'

	data := tx.execute(query, ...params)!

	rows := data.rows()

	mut stock_locations := []StockLocation{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()

		id_bin, _ := v[0].get_array_u8()!
		created_at, _ := v[1].get_date_time()!
		updated_at, _ := v[2].get_date_time()!
		deleted_at := v[3].get_null_date_time()!
		name, _ := v[4].get_string()!

		id := id_from_bytes(id_bin)!

		stock_locations[i] = StockLocation{
			id:         id
			created_at: created_at
			updated_at: updated_at
			deleted_at: deleted_at.none_value()
			name:       name
		}
	}

	return stock_locations
}

// NOTE: when an item_reservation is removed, it should not restore item_availability if stock_location.deleted_at is not null
pub fn stock_location_delete(mut tx firebird.ClientTransaction, stock_location_id ID) ! {
	result := tx.execute('UPDATE stock_location
		SET deleted_at = CURRENT_TIMESTAMP
		WHERE id = ?
		AND deleted_at IS NULL',
		stock_location_id)!

	if result.affected_rows() == 0 { // stock_location was already deleted
		return
	}

	tx.execute('MERGE INTO item_availability t
		USING (
			SELECT il.inventory_item_id, scsl.sales_channel_id, il.stocked_quantity
			FROM inventory_level il
			JOIN sales_channel_stock_location scsl
				ON scsl.stock_location_id = il.stock_location_id
			WHERE il.stock_location_id = ?
		) s (item_id, sales_channel_id, stocked_quantity)
		ON t.item_id = s.item_id
			AND t.sales_channel_id = s.sales_channel_id
		WHEN MATCHED THEN UPDATE
			SET t.amount = t.amount - s.stocked_quantity',
		stock_location_id.bytes())!
}
