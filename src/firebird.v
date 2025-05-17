module main

// import arrays
// import log
import einar_hjortdal.luuid
import einar_hjortdal.firebird
import os

const schema_file = $embed_file('migrations/seed-schema.sql')
const country_codes_file = $embed_file('migrations/seed-country-codes.txt')
const currency_codes_file = $embed_file('migrations/seed-currency-codes.txt')
const locale_codes_file = $embed_file('migrations/seed-locale-codes.txt')
const default_locale_code = 'en'
const default_currency_code = 'EUR'

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
		tx.execute(q)!
		tx.commit()!
	}
}

fn add_data(mut conn firebird.Connection, mut g luuid.Generator) ! {
	country_codes := get_country_codes()
	currency_codes := get_currency_codes()
	locale_codes := get_locale_codes()

	mut tx := conn.start_transaction(firebird.isolation_level_read_commited)!

	mut stmt := tx.prepare('INSERT INTO country (code) VALUES (?)')!
	for i := 0; i < country_codes.len; i++ {
		code := country_codes[i]
		stmt.execute(code)!
	}
	stmt.close()!

	stmt = tx.prepare('INSERT INTO currency (code) VALUES (?)')!
	for i := 0; i < currency_codes.len; i++ {
		code := currency_codes[i]
		stmt.execute(code)!
	}
	stmt.close()!

	stmt = tx.prepare('INSERT INTO locale (id, code) VALUES (?, ?)')!
	for i := 0; i < locale_codes.len; i++ {
		_, id_bin := new_id(mut g)!
		code := locale_codes[i]
		stmt.execute(id_bin, code)!
	}
	stmt.close()!

	user_id, user_id_bin := new_id(mut g)!
	user_email := os.getenv(env_email)
	password_salt, password_hash := hash_password(os.getenv(env_password))!
	tx.execute('INSERT INTO user (id, handle, email, password_hash, password_salt, role)
	VALUES (?, ?, ?, ?, ?, ?)',
		user_id_bin, user_id, user_email, password_hash, password_salt, role_admin)!

	sales_channel_id, sales_channel_id_bin := new_id(mut g)!
	tx.execute('INSERT INTO sales_channel (id, name) VALUES (?, ?)', sales_channel_id_bin,
		sales_channel_id)!

	stock_location_id, stock_location_id_bin := new_id(mut g)!
	tx.execute('INSERT INTO stock_location (id, name) VALUES (?, ?)', stock_location_id_bin,
		stock_location_id)!

	store_id, store_id_bin := new_id(mut g)!
	tx.execute('INSERT INTO store (
	id, name, default_locale_code, default_currency_code, default_stock_location_id, default_sales_channel_id)
	VALUES (?, ?, ?, ?, ?, ?)',
		store_id_bin, store_id, default_locale_code, default_currency_code, stock_location_id_bin,
		sales_channel_id_bin)!

	tx.execute('INSERT INTO store_locales (store_id, locale_code) VALUES (?, ?)', store_id_bin,
		default_locale_code)!

	tx.execute('INSERT INTO store_currencies (store_id, currency_code) VALUES (?, ?)',
		store_id_bin, default_currency_code)!

	tx.commit()!
}

// TODO if error rollback all changes
// Can't just do tx.rollback() because each table is created in its own transaction.
fn prepare_db(mut conn firebird.Connection, mut g luuid.Generator) ! {
	if database_is_ready(mut conn) {
		return
	}
	create_schema(mut conn)!
	add_data(mut conn, mut g)!
}
