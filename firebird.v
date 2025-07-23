module peony

import log
import os
import strconv
import einar_hjortdal.firebird

const schema_file = $embed_file('migrations/seed-schema.sql')
const schema_rollback_file = $embed_file('migrations/seed-rollback.sql')
const country_codes_file = $embed_file('migrations/seed-country-codes.txt')
const currency_file = $embed_file('migrations/seed-currency.txt')
const locale_codes_file = $embed_file('migrations/seed-locale-codes.txt')
const seed_default_store_name = 'peony store'
const seed_default_locale_code = 'en'
const seed_default_currency_code = 'EUR'
const seed_migration_name = 'seed'

fn get_schema_queries() []string {
	queries := schema_file.to_string().split(';')
	return queries[..queries.len - 1] // remove last character \n (posix)
}

fn get_schema_rollback_queries() []string {
	queries := schema_rollback_file.to_string().split(';')
	return queries[..queries.len - 1] // remove last character \n (posix)
}

fn get_country_codes() []string {
	country_codes := country_codes_file.to_string().split('\n')
	return country_codes[..country_codes.len - 1] // remove last character \n (posix)
}

fn get_currency_data() []string {
	currency_codes := currency_file.to_string().split('\n')
	return currency_codes[..currency_codes.len - 1] // remove last character \n (posix)
}

fn get_locale_codes() []string {
	locale_codes := locale_codes_file.to_string().split('\n')
	return locale_codes[..locale_codes.len - 1] // remove last character \n (posix)
}

fn (mut app App) insert_country_codes(mut tx firebird.Transaction) ! {
	log.debug('insert_country_codes')
	country_codes := get_country_codes()
	mut stmt := tx.prepare('INSERT INTO country (code) VALUES (?)')!
	for i := 0; i < country_codes.len; i++ {
		code := country_codes[i]
		stmt.execute(code)!
	}
	stmt.close()!
}

fn (mut app App) insert_currency_data(mut tx firebird.Transaction) ! {
	log.debug('insert_currency_data')
	currency_data := get_currency_data()
	mut stmt := tx.prepare('INSERT INTO currency (code, decimal_digits) VALUES (?, ?)')!
	for i := 0; i < currency_data.len; i++ {
		data := currency_data[i].split(',')
		code := data[0]
		decimal_digits_string := data[1]
		decimal_digits := strconv.parse_int(decimal_digits_string, 10, 32) or {
			stmt.execute(code, firebird.Null{})!
			continue
		}
		stmt.execute(code, decimal_digits)!
	}
	stmt.close()!
}

fn (mut app App) insert_locale_codes(mut tx firebird.Transaction) ! {
	log.debug('insert_locale_codes')
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
	log.debug('insert_default_user')
	id, id_bin := app.new_id()!
	email := os.getenv(env_email)
	password_salt, password_hash := hash_password(os.getenv(env_password))!
	tx.execute('INSERT INTO app_user (id, handle, email, password_hash, password_salt, role)
	VALUES (?, ?, ?, ?, ?, ?)',
		id_bin, id, email, password_hash, password_salt, role_admin)!
}

fn (mut app App) insert_default_stock_location(mut tx firebird.Transaction) ![]u8 {
	log.debug('insert_default_stock_location')
	stock_location_id, stock_location_id_bin := app.new_id()!
	tx.execute('INSERT INTO stock_location (id, name) VALUES (?, ?)', stock_location_id_bin,
		stock_location_id)!
	return stock_location_id_bin
}

fn (mut app App) insert_default_sales_channel(mut tx firebird.Transaction) ![]u8 {
	log.debug('insert_default_sales_channel')
	sales_channel_id, sales_channel_id_bin := app.new_id()!
	tx.execute('INSERT INTO sales_channel (id, name) VALUES (?, ?)', sales_channel_id_bin,
		sales_channel_id)!
	return sales_channel_id_bin
}

fn (mut app App) insert_default_store(mut tx firebird.Transaction, stock_location_id_bin []u8,
	sales_channel_id_bin []u8) ![]u8 {
	log.debug('insert_default_store')
	_, store_id_bin := app.new_id()!
	tx.execute('INSERT INTO store (
	id, name, default_locale_id, default_currency_code, default_stock_location_id, default_sales_channel_id)
	VALUES (?, ?, (SELECT id FROM locale WHERE code = ?), ?, ?, ?)',
		store_id_bin, seed_default_store_name, seed_default_locale_code, seed_default_currency_code,
		stock_location_id_bin, sales_channel_id_bin)!
	return store_id_bin
}

fn (mut app App) insert_default_store_locale(mut tx firebird.Transaction, store_id_bin []u8) ! {
	log.debug('insert_default_store_locale')
	tx.execute('INSERT INTO store_locales (store_id, locale_id)
		VALUES (?, (SELECT id FROM locale WHERE code = ?))',
		store_id_bin, seed_default_locale_code)!
}

fn (mut app App) insert_default_store_currency(mut tx firebird.Transaction, store_id_bin []u8) ! {
	log.debug('insert_default_store_currency')
	tx.execute('INSERT INTO store_currencies (store_id, currency_code) VALUES (?, ?)',
		store_id_bin, seed_default_currency_code)!
}

fn create_schema(mut conn firebird.Connection) ! {
	log.debug('create_schema')
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

fn rollback_schema(mut conn firebird.Connection) ! {
	log.debug('rollback_schema')
	rollback_queries := get_schema_rollback_queries()
	for i := 0; i < rollback_queries.len; i++ {
		q := rollback_queries[i]
		mut tx := conn.start_transaction(firebird.isolation_level_read_commited) or {
			log.error('Could not rollback schema, manual intervention may be required.')
			log.debug('Failed to start transaction')
			return err
		}
		tx.execute(q) or { log.debug('Failed to execute query: ${q}') } // ignore error
		tx.commit() or {
			log.error('Could not rollback schema, manual intervention may be required.')
			log.debug('Failed to commit changes')
			return err
		}
	}
	log.debug('Rollback complete')
}

fn (mut app App) add_data(mut tx firebird.Transaction) ! {
	app.insert_country_codes(mut tx)!
	app.insert_currency_data(mut tx)!
	app.insert_locale_codes(mut tx)!
	app.insert_default_user(mut tx)!
	stock_location_id_bin := app.insert_default_stock_location(mut tx)!
	sales_channel_id_bin := app.insert_default_sales_channel(mut tx)!
	store_id_bin := app.insert_default_store(mut tx, stock_location_id_bin, sales_channel_id_bin)!
	app.insert_default_store_locale(mut tx, store_id_bin)!
	app.insert_default_store_currency(mut tx, store_id_bin)!
	app.do_create_migration(mut tx, seed_migration_name)!
}

fn (mut app App) is_ready() !bool {
	migrations := app.retrieve_migrations() or {
		if err.msg().contains('Table unknown') {
			log.info('Database needs setup: migration table missing')
			return false
		} else {
			log.error('Could not retrieve migrations')
			return err
		}
	}

	if migration := find_migration(migrations, seed_migration_name) {
		log.info('Store created at ${migration.created_at.Time}')
		return true
	}

	return error('Database contains a migration table, but it lacks a row with name `${seed_migration_name}`.
		Database may be corrupt, manual intervention is required.')
}

// panics on errors
fn (mut app App) prepare_db() {
	is_ready := app.is_ready() or { panic(err) }
	if is_ready {
		return
	}

	log.info('Setting up database')

	create_schema(mut app.firebird) or {
		log.error('Failed to create schema, rolling back...')
		rollback_schema(mut app.firebird) or {
			log.error('Failed to rollback schema, manual intervention may be required')
		}
		panic(err)
	}

	mut tx := app.start_transaction() or {
		log.error('Failed to start transaction, manual intervention may be required')
		panic(err)
	}

	app.add_data(mut tx) or {
		log.error('Failed to add default data to database, rolling back...')
		tx.rollback() or { log.error('Failed to rollback transaction') }
		rollback_schema(mut app.firebird) or {
			log.error('Failed to rollback schema, manual intervention may be required')
		}
		panic(err)
	}

	tx.commit() or {
		log.error('Failed to commit changes to database, manual intervention may be required')
		panic(err)
	}

	log.info('Database setup complete')
}
