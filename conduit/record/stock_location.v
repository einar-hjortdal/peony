module record

import arrays
import einar_hjortdal.firebird

pub struct StockLocation {
	id         ID
	created_at firebird.DateTime
	updated_at firebird.DateTime
	deleted_at firebird.NullDateTime
	name       string
	// address Address
}

pub fn (sl StockLocation) id() ID {
	return sl.id
}

// TODO fetch, order...
pub struct StockLocationRetrieveParams {
pub:
	ids ?[]ID
}

fn stock_location_retrieve_conditions(p StockLocationRetrieveParams) (string, []firebird.Value) {
	mut conditions := []string{}
	mut params := []firebird.Value{}

	if ids := p.ids {
		conditions = arrays.concat(conditions, 'id IN (${get_placeholders(ids)})')
		params = arrays.concat(params, ...ids_bytes(ids))
	}

	return get_where_conditions(conditions), params
}

pub fn stock_location_retrieve_count(mut tx firebird.Transaction, p StockLocationRetrieveParams) !i64 {
	conditions, params := stock_location_retrieve_conditions(p)
	data := tx.execute('SELECT COUNT(*) FROM stock_location ${conditions}', ...params)!
	rows := data.rows()
	values := rows[0].values() // should always return one row
	count, _ := values[0].get_i64()! // should always return one column
	return count
}

pub fn stock_location_retrieve(mut tx firebird.Transaction, p StockLocationRetrieveParams) ![]StockLocation {
	conditions, mut params := stock_location_retrieve_conditions(p)

	data := tx.execute('SELECT id, created_at, updated_at, deleted_at, name, address_id 
		FROM stock_location ${conditions}',
		...params)!

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
			deleted_at: deleted_at
			name:       name
		}
	}

	return stock_locations
}

