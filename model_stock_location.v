module peony

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

fn model_stock_location_get(mut tx firebird.Transaction) ![]StockLocation {
	data := tx.execute('SELECT id, created_at, updated_at, deleted_at, name, address_id 
		FROM stock_location')!

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
