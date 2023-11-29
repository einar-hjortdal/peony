module main

// vlib
import arrays
import db.mysql as v_mysql
import log
import os
// local
import models
import data.mysql
import utils
// first party
import coachonko.luuid

const default_email = 'default_admin@peony.com'
const default_password = 'peony_default_password'

// execute_mysql_script executes a mysql script by reading the script data.
// This command expects properly formatted MySQL scripts. Each query must end with a semicolon.
fn execute_mysql_script(file_path string, mut mysql_conn v_mysql.DB) {
	file_data := os.read_file(file_path) or { panic(err) }
	// Separate commands by the semicolon
	split_data := file_data.split(';')
	// Strip newline characters from start and end of each query.
	// This is not strictly necessary, but it outputs prettier queries.
	// Note that the last element is skipped, this is because it is an empty string.
	mut trimmed_data := []string{}
	for data_string in split_data[0..split_data.len - 1] {
		trimmed_data = arrays.concat(trimmed_data, data_string.trim('\n'))
	}
	for query in trimmed_data {
		mysql_conn.real_query(query) or { panic(err) } // TODO cleanup when panic
	}
}

// setup_schema seeds an empty MySQL database for peony
fn setup_schema(mut logger log.Log, mut mysql_conn v_mysql.DB) {
	logger.info('Preparing database schema')

	execute_mysql_script('src/migrations/seed-schema.sql', mut mysql_conn)
}

// add_currency_codes adds ISO 4217 currency codes into the currency table.
// Currency codes are stored in a text file, each currency code is on its own line.
// This function expects no line is empty in the text file.
fn add_currency_codes(mut logger log.Log, mut mysql_conn v_mysql.DB, mut luuid_gen luuid.Generator) {
	file_data := os.read_file('src/migrations/seed-currency-codes.txt') or { panic(err) }
	lines := file_data.split('\n')

	logger.debug('Adding currency codes to the database')

	for line in lines {
		new_currency_id := luuid_gen.v2() or { panic(err) }
		query_string := "INSERT INTO currency (id, code) VALUES (UUID_TO_BIN('${new_currency_id}'), '${line}')"
		mysql_conn.real_query(query_string) or { panic(err) }
	}
}

// add_country_codes adds ISO 3166-1 alpha 2 country codes into the country table.
// Country data is stored in a text file, each country code is on its own line.
// This function expects no line is empty in the text file.
fn add_country_codes(mut logger log.Log, mut mysql_conn v_mysql.DB, mut luuid_gen luuid.Generator) {
	file_data := os.read_file('src/migrations/seed-country-codes.txt') or { panic(err) }
	lines := file_data.split('\n')

	logger.debug('Adding country codes to the database')

	for line in lines {
		new_country_id := luuid_gen.v2() or { panic(err) }
		query_string := "INSERT INTO country (id, code) VALUES (UUID_TO_BIN('${new_country_id}'), '${line}')"
		mysql_conn.real_query(query_string) or { panic(err) }
	}
}

// add_locale_codes adds the most common locale codes into the locale table.
// These codes are composed of the ISO 639-1 language code plus an optional region or script modifier.
// Locale data is stored in a text file, each locale code is on its own line.
// This function expects no line is empty in the text file.
fn add_locale_codes(mut logger log.Log, mut mysql_conn v_mysql.DB, mut luuid_gen luuid.Generator) {
	file_data := os.read_file('src/migrations/seed-locale-codes.txt') or { panic(err) }
	lines := file_data.split('\n')

	logger.debug('Adding locale codes to the database')

	for line in lines {
		new_locale_id := luuid_gen.v2() or { panic(err) }
		query_string := "INSERT INTO locale (id, code) VALUES (UUID_TO_BIN('${new_locale_id}'), '${line}')"
		mysql_conn.real_query(query_string) or { panic(err) }
	}
}

// add_store inserts a new store entry in the store table.
fn add_store(mut logger log.Log, mut mysql_conn v_mysql.DB, mut luuid_gen luuid.Generator) {
	logger.debug('Adding default store to the database')

	new_store_id := luuid_gen.v2() or { panic(err) }
	store := models.StoreWriteable{}
	store.create(mut mysql_conn, new_store_id) or { panic(err) }

	logger.debug('The randomly generated store ID is ${new_store_id}')
}

// add_default_admin creates the default admin in the table user
fn add_default_admin(mut logger log.Log, mut mysql_conn v_mysql.DB, mut luuid_gen luuid.Generator) {
	logger.debug('Adding default admin to the database')

	new_admin_id := luuid_gen.v2() or { panic(err) }
	new_admin_handle := 'default_admin'
	new_password_hash := utils.new_password_hash(default_password) or { panic(err) }
	user := models.UserWriteable{
		email: default_email
		password_hash: new_password_hash
		handle: new_admin_handle
		role: 'admin'
	}
	user.create(mut mysql_conn, new_admin_id) or { panic(err) }

	logger.info('The default admin email is ${default_email}')
	logger.info('The default admin password is ${default_password}')
	logger.warn('It is recommended to change password for the default user account')
}

// add_data adds necessary data and default entries in the database
fn setup_data(mut logger log.Log, mut mysql_conn v_mysql.DB, mut luuid_gen luuid.Generator) {
	logger.info('Data is being added to the database')

	add_currency_codes(mut logger, mut mysql_conn, mut luuid_gen)
	add_country_codes(mut logger, mut mysql_conn, mut luuid_gen)
	add_locale_codes(mut logger, mut mysql_conn, mut luuid_gen)
	add_store(mut logger, mut mysql_conn, mut luuid_gen)
	add_default_admin(mut logger, mut mysql_conn, mut luuid_gen)
}

// needs_setup returns true if the database does not contain the user table.
fn needs_setup(mut logger log.Log, mut mysql_conn v_mysql.DB) bool {
	query := "SELECT EXISTS(
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = ?
    AND table_name = 'user'
	)"
	table_schema := os.getenv('MYSQL_DATABASE')
	result := mysql.prep_n_exec(mut mysql_conn, query, table_schema) or { panic(err) }
	if result.rows()[0].vals[0] == '1' {
		return false
	} else {
		return true
	}
}

// check_default_admin warns the user if the default admin account still uses the default email address
fn check_default_admin(mut logger log.Log, mut mysql_conn v_mysql.DB) {
	if _ := models.user_retrieve_by_email(mut mysql_conn, default_email) {
		logger.warn('It is recommended to change both email and password for the default user account')
	}
}

// prepare_db creates the initial schema and enters default data in the database only if needed.
// It is expected that tables created by peony are never manually edited nor deleted.
// If setup_schema() and/or add_defaults() fail, manually use seed-rollback.sql to revert all changes
// or drop and re-create the database for peony.
fn prepare_db(mut logger log.Log) {
	// This function requires a connection to the MySQL server.
	// Such a connection cannot be provided by the vweb pool because vweb has not been started yet.
	mut mysql_conn := mysql.new_mysql_conn()
	mut luuid_gen := luuid.new_generator()
	if needs_setup(mut logger, mut mysql_conn) {
		setup_schema(mut logger, mut mysql_conn)
		setup_data(mut logger, mut mysql_conn, mut luuid_gen)
	} else {
		check_default_admin(mut logger, mut mysql_conn)
	}
	mysql_conn.close()
}
