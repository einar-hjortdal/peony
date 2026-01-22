module peony

import arrays
import einar_hjortdal.firebird

struct StockLocation {
	id         string
	id_bin     []u8
	created_at firebird.DateTime
	updated_at firebird.DateTime
	deleted_at firebird.NullDateTime
	name       string
	// address Address
}

struct StockLocationRetrieveParams {
	filter_by_id bool
	ids_bin      [][]u8
}

fn model_stock_location_retrieve_conditions(p StockLocationRetrieveParams) (string, []firebird.Value) {
	mut conditions := []string{}
	mut params := []firebird.Value{}

	if p.filter_by_id {
		conditions = arrays.concat(conditions, 'id IN (${get_placeholders(p.ids_bin)})')
		params = arrays.concat(params, ...workaround_24757(p.ids_bin))
	}

	return get_where_conditions(conditions), params
}

fn model_stock_location_retrieve_count(mut tx firebird.Transaction, p StockLocationRetrieveParams) !i64 {
	conditions, params := model_stock_location_retrieve_conditions(p)
	data := tx.execute('SELECT COUNT(*) FROM stock_location ${conditions}', ...params)!
	rows := data.rows()
	values := rows[0].values() // should always return one row
	count, _ := values[0].get_i64()! // should always return one column
	return count
}

fn model_stock_location_retrieve(mut tx firebird.Transaction, p StockLocationRetrieveParams) ![]StockLocation {
	conditions, mut params := model_stock_location_retrieve_conditions(p)

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

		id := id_bin_to_string(id_bin)!

		stock_locations[i] = StockLocation{
			id:         id
			id_bin:     id_bin
			created_at: created_at
			updated_at: updated_at
			deleted_at: deleted_at
			name:       name
		}
	}

	return stock_locations
}
