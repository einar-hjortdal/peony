module main

// import arrays
import log
import einar_hjortdal.firebird
import os

const schema_file = $embed_file('migrations/seed-schema.sql')
const country_codes_file = $embed_file('migrations/seed-country-codes.txt')
const currency_codes_file = $embed_file('migrations/seed-currency-codes.txt')
const locale_codes_file = $embed_file('migrations/seed-locale-codes.txt')
const seed_default_locale_code = 'en'
const seed_default_currency_code = 'EUR'

fn get_schema_queries() []string {
	queries := schema_file.to_string().split(';')
	return queries[..queries.len - 1] // remove last character \n (posix)
}

fn get_country_codes() []string {
	country_codes := country_codes_file.to_string().split('\n')
	return country_codes[..country_codes.len - 1] // remove last character \n (posix)
}

fn get_currency_codes() []string {
	currency_codes := currency_codes_file.to_string().split('\n')
	return currency_codes[..currency_codes.len - 1] // remove last character \n (posix)
}

fn get_locale_codes() []string {
	locale_codes := locale_codes_file.to_string().split('\n')
	return locale_codes[..locale_codes.len - 1] // remove last character \n (posix)
}

fn (mut app App) insert_country_codes(mut tx firebird.Transaction) ! {
	country_codes := get_country_codes()
	mut stmt := tx.prepare('INSERT INTO country (code) VALUES (?)')!
	for i := 0; i < country_codes.len; i++ {
		code := country_codes[i]
		stmt.execute(code)!
	}
	stmt.close()!
}

fn (mut app App) insert_currency_codes(mut tx firebird.Transaction) ! {
	currency_codes := get_currency_codes()
	mut stmt := tx.prepare('INSERT INTO currency (code) VALUES (?)')!
	for i := 0; i < currency_codes.len; i++ {
		code := currency_codes[i]
		stmt.execute(code)!
	}
	stmt.close()!
}

fn (mut app App) insert_locale_codes(mut tx firebird.Transaction) ! {
	locale_codes := get_locale_codes()
	mut stmt := tx.prepare('INSERT INTO locale (id, code) VALUES (?, ?)')!
	for i := 0; i < locale_codes.len; i++ {
		_, id_bin := app.new_id()!
		code := locale_codes[i]
		stmt.execute(id_bin, code)!
	}
	stmt.close()!
}

fn (mut app App) insert_default_user(mut tx firebird.Transaction) ! {
	id, id_bin := app.new_id()!
	email := os.getenv(env_email)
	password_salt, password_hash := hash_password(os.getenv(env_password))!
	tx.execute('INSERT INTO app_user (id, handle, email, password_hash, password_salt, role)
	VALUES (?, ?, ?, ?, ?, ?)',
		id_bin, id, email, password_hash, password_salt, role_admin)!
}

fn (mut app App) insert_default_stock_location(mut tx firebird.Transaction) ![]u8 {
	stock_location_id, stock_location_id_bin := app.new_id()!
	tx.execute('INSERT INTO stock_location (id, name) VALUES (?, ?)', stock_location_id_bin,
		stock_location_id)!
	return stock_location_id_bin
}

fn (mut app App) insert_default_sales_channel(mut tx firebird.Transaction) ![]u8 {
	sales_channel_id, sales_channel_id_bin := app.new_id()!
	tx.execute('INSERT INTO sales_channel (id, name) VALUES (?, ?)', sales_channel_id_bin,
		sales_channel_id)!
	return sales_channel_id_bin
}

fn (mut app App) insert_default_store(mut tx firebird.Transaction, stock_location_id_bin []u8,
	sales_channel_id_bin []u8) ![]u8 {
	store_id, store_id_bin := app.new_id()!
	tx.execute('INSERT INTO store (
	id, name, default_locale_code, default_currency_code, default_stock_location_id, default_sales_channel_id)
	VALUES (?, ?, ?, ?, ?, ?)',
		store_id_bin, store_id, seed_default_locale_code, seed_default_currency_code,
		stock_location_id_bin, sales_channel_id_bin)!
	return store_id_bin
}

fn (mut app App) insert_default_store_locale(mut tx firebird.Transaction, store_id_bin []u8) ! {
	tx.execute('INSERT INTO store_locales (store_id, locale_code) VALUES (?, ?)', store_id_bin,
		seed_default_locale_code)!
}

fn (mut app App) insert_default_store_currency(mut tx firebird.Transaction, store_id_bin []u8) ! {
	tx.execute('INSERT INTO store_currencies (store_id, currency_code) VALUES (?, ?)',
		store_id_bin, seed_default_currency_code)!
}

fn database_is_ready(mut conn firebird.Connection) bool {
	// assume the database is ready if get_store_data does not fail
	if _ := get_store_data(mut conn) {
		return true
	}
	return false
}

fn create_schema(mut conn firebird.Connection) ! {
	schema_queries := get_schema_queries()
	for i := 0; i < schema_queries.len; i++ {
		q := schema_queries[i]
		mut tx := conn.start_transaction(firebird.isolation_level_read_commited)!
		tx.execute(q) or {
			log.debug('Failed to execute query: ${q}')
			return err
		}
		tx.commit()!
	}
}

fn (mut app App) add_data(mut tx firebird.Transaction) ! {
	app.insert_country_codes(mut tx)!
	app.insert_currency_codes(mut tx)!
	app.insert_locale_codes(mut tx)!
	app.insert_default_user(mut tx)!
	stock_location_id_bin := app.insert_default_stock_location(mut tx)!
	sales_channel_id_bin := app.insert_default_sales_channel(mut tx)!
	store_id_bin := app.insert_default_store(mut tx, stock_location_id_bin, sales_channel_id_bin)!
	app.insert_default_store_locale(mut tx, store_id_bin)!
	app.insert_default_store_currency(mut tx, store_id_bin)!
}

fn (mut app App) prepare_db() ! {
	if database_is_ready(mut app.firebird) {
		return
	}

	// TODO if error rollback all changes
	// Can't just do tx.rollback() because each table is created in its own transaction.
	// Instead a rollback file needs to be created where tables and constrats are dropped in reverse order.
	create_schema(mut app.firebird)!

	mut tx := app.start_transaction()!
	app.add_data(mut tx) or {
		tx.rollback()!
		return err
	}
	tx.commit()!
}
