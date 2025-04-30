module main

import einar_hjortdal.firebird

struct Store {
	id                        string
	created_at                firebird.DateTime
	updated_at                firebird.DateTime
	name                      string
	default_locale_code       string
	default_currency_code     string
	default_stock_location_id firebird.NullString
	default_sales_channel_id  firebird.NullString
}

fn parse_store_data(data []firebird.Value) !Store {
	id, _ := firebird.get_string(data[0])!
	created_at, _ := firebird.get_date_time(data[1])!
	updated_at, _ := firebird.get_date_time(data[2])!
	name, _ := firebird.get_string(data[3])!
	default_locale_code, _ := firebird.get_string(data[4])!
	default_currency_code, _ := firebird.get_string(data[5])!
	default_stock_location_id := firebird.get_null_string(data[6])!
	default_sales_channel_id := firebird.get_null_string(data[7])!

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
		id,
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
	return parse_store_data(data)
}
