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

fn add_data(mut conn firebird.Connection, mut gen luuid.Generator) ! {
	country_codes := get_country_codes()
	currency_codes := get_currency_codes()
	locale_codes := get_locale_codes()

	mut tx := conn.start_transaction(firebird.isolation_level_read_commited)!

	mut stmt := tx.prepare('INSERT INTO country (id, code) VALUES (?, ?)')!
	for i := 0; i < country_codes.len; i++ {
		id := gen.v1()
		code := country_codes[i]
		stmt.execute(id, code)!
	}
	stmt.close()!

	stmt = tx.prepare('INSERT INTO currency (id, code) VALUES (?, ?)')!
	for i := 0; i < currency_codes.len; i++ {
		id := gen.v1()
		code := currency_codes[i]
		stmt.execute(id, code)!
	}
	stmt.close()!

	stmt = tx.prepare('INSERT INTO locale (id, code) VALUES (?, ?)')!
	for i := 0; i < locale_codes.len; i++ {
		id := gen.v1()
		code := locale_codes[i]
		stmt.execute(id, code)!
	}
	stmt.close()!

	user_id := gen.v1()
	user_handle := gen.v1()
	user_email := os.getenv(env_email)
	password_salt, password_hash := hash_password(os.getenv(env_password))!
	tx.execute('INSERT INTO user (id, handle, email, password_hash, password_salt, role)
	VALUES (?, ?, ?, ?, ?, ?)',
		user_id, user_handle, user_email, password_hash, password_salt, role_admin)!

	tx.commit()!
}

// TODO if error rollback all changes
// Can't just do tx.rollback() because each table is created in its own transaction.
fn prepare_db(mut conn firebird.Connection, mut gen luuid.Generator) ! {
	if database_is_ready(mut conn) {
		return
	}
	create_schema(mut conn)!
	add_data(mut conn, mut gen)!
}
