module main

import arrays
import einar_hjortdal.firebird

struct Store {
	id                            string
	id_bin                        []u8
	created_at                    firebird.DateTime
	updated_at                    firebird.DateTime
	name                          string
	default_locale_code           string
	default_currency_code         string
	default_stock_location_id     string
	default_stock_location_id_bin []u8
	default_sales_channel_id      string
	default_sales_channel_id_bin  []u8
mut:
	locales    []Locale
	currencies []Currency
}

fn parse_store(v []firebird.Value) !Store {
	id_bin, _ := v[0].get_array_u8()!
	created_at, _ := v[1].get_date_time()!
	updated_at, _ := v[2].get_date_time()!
	name, _ := v[3].get_string()!
	default_locale_code, _ := v[4].get_string()!
	default_currency_code, _ := v[5].get_string()!
	default_stock_location_id_bin, default_stock_location_id_bin_is_null := v[6].get_array_u8()!
	default_sales_channel_id_bin, default_sales_channel_id_bin_is_null := v[7].get_array_u8()!

	id := id_bin_to_string(id_bin)!

	mut default_stock_location_id := ''
	mut default_sales_channel_id := ''

	if !default_stock_location_id_bin_is_null {
		default_stock_location_id = id_bin_to_string(default_stock_location_id_bin)!
	}

	if !default_sales_channel_id_bin_is_null {
		default_sales_channel_id = id_bin_to_string(default_sales_channel_id_bin)!
	}

	return Store{
		id:                            id
		id_bin:                        id_bin
		created_at:                    created_at
		updated_at:                    updated_at
		name:                          name
		default_locale_code:           default_locale_code
		default_currency_code:         default_currency_code
		default_stock_location_id:     default_stock_location_id
		default_stock_location_id_bin: default_stock_location_id_bin
		default_sales_channel_id:      default_sales_channel_id
		default_sales_channel_id_bin:  default_sales_channel_id_bin
	}
}

fn do_retrieve_store(mut tx firebird.Transaction) !Store {
	store_data := tx.execute('SELECT
		id,
		created_at,
		updated_at,
		name,
		default_locale_code,
		default_currency_code,
		default_stock_location_id,
		default_sales_channel_id
		FROM store')!

	if store_data.rows.len == 0 {
		return error(format_error_message('No entries in table store'))
	}

	mut store := parse_store(store_data.rows[0].values)!

	locale_data := tx.execute('SELECT locale_code FROM store_locales WHERE store_id = ?',
		store.id_bin)!

	mut locales := []Locale{len: locale_data.rows.len}
	for i := 0; i < locale_data.rows.len; i++ {
		locales[i] = parse_locale(locale_data.rows[i].values)!
	}

	store.locales = locales

	currency_data := tx.execute('SELECT currency_code, c.includes_tax 
		FROM store_currencies
		LEFT JOIN currency c ON currency_code = c.code
		WHERE store_id = ?',
		store.id_bin)!

	mut currencies := []Currency{len: currency_data.rows.len}
	for i := 0; i < currency_data.rows.len; i++ {
		currencies[i] = parse_currency(currency_data.rows[i].values)!
	}

	store.currencies = currencies

	return store
}

fn (mut app App) store_retrieve() !Store {
	mut tx := app.start_transaction()!
	store := do_retrieve_store(mut tx) or {
		tx.rollback()!
		return err
	}
	tx.rollback()!
	return store
}

fn (mut app App) update_store_data(id_bin []u8, p NewStoreData) ! {
	mut query := 'UPDATE store SET'
	mut params := []firebird.Value{}

	if name := p.name {
		query = appendln(query, 'name = ?')
		params = arrays.concat(params, name)
	}

	if default_locale_code := p.default_locale_code {
		query = appendln(query, 'default_locale_code = ?')
		params = arrays.concat(params, default_locale_code)
	}

	if default_currency_code := p.default_currency_code {
		query = appendln(query, 'default_currency_code = ?')
		params = arrays.concat(params, default_currency_code)
	}

	conditions := 'WHERE id = ?'
	query = appendln(query, conditions)
	params = arrays.concat(params, id_bin)

	mut tx := app.start_transaction()!
	tx.execute(query, ...params)!
	tx.commit()!
}
