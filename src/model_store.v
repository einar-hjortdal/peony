module main

import einar_hjortdal.firebird

struct Store {
	id                        string
	created_at                firebird.DateTime
	updated_at                firebird.DateTime
	name                      string
	default_locale_code       string
	default_currency_code     string
	default_stock_location_id string @[omitempty]
	default_sales_channel_id  string @[omitempty]
}

fn parse_store(v []firebird.Value) !Store {
	id, _ := v[0].get_string()!
	created_at, _ := v[1].get_date_time()!
	updated_at, _ := v[2].get_date_time()!
	name, _ := v[3].get_string()!
	default_locale_code, _ := v[4].get_string()!
	default_currency_code, _ := v[5].get_string()!
	default_stock_location_id, _ := v[6].get_string()!
	default_sales_channel_id, _ := v[7].get_string()!

	return Store{
		id:                        id
		created_at:                created_at
		updated_at:                updated_at
		name:                      name
		default_locale_code:       default_locale_code
		default_currency_code:     default_currency_code
		default_stock_location_id: default_stock_location_id
		default_sales_channel_id:  default_sales_channel_id
	}
}

fn get_store_data(mut conn firebird.Connection) ![]firebird.Value {
	mut tx := conn.start_transaction(firebird.isolation_level_read_commited)!
	res := tx.execute('SELECT (
		UUID_TO_CHAR(id),
		created_at,
		updated_at,
		name,
		default_locale_code,
		default_currency_code,
		default_stock_location_id,
		default_sales_channel_id
		) FROM store')!
	tx.rollback()!

	if res.rows.len == 0 {
		return error(format_error_message('No entries in table store'))
	}

	return res.rows[0].values
}

fn (mut app App) store_retrieve() !Store {
	data := get_store_data(mut app.fb)!
	return parse_store(data)
}

struct NewStoreData {
	name                  string
	default_locale_code   string
	default_currency_code string
}

fn (mut app App) update_store_data(id string, data NewStoreData) ! {
	mut tx := app.fb.start_transaction(firebird.isolation_level_read_commited)!
	tx.execute('UPDATE store SET name = ?, default_locale_code = ?, default_currency_code = ?
	WHERE id = CHAR_TO_UUID(?)',
		data.name, data.default_locale_code, data.default_currency_code, id)!
	tx.commit()!
}
