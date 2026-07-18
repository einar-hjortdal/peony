module peony

import log
import strconv
import einar_hjortdal.luuid
import einar_hjortdal.firebird
import internal.conduit.record
import internal.common
import objects

// TODO this should be own module, merge with migrations directory. Is allowed to call record functions directly.

const schema_file = $embed_file('migrations/seed-schema.sql')
const schema_rollback_file = $embed_file('migrations/seed-rollback.sql')
const country_codes_file = $embed_file('migrations/seed-country-codes.txt')
const currency_file = $embed_file('migrations/seed-currency.txt')
const locale_codes_file = $embed_file('migrations/seed-locale-codes.txt')
const seed_migration_name = 'seed'

const seed_default_region_name = 'default region'
const seed_default_stock_location_name = 'default stock location'
const seed_default_sales_channel_name = 'default sales channel'
const seed_default_api_key_name = 'default api key'
const seed_default_store_name = 'peony store'
const seed_default_locale_code = normalize_code('en')
const seed_default_region_country = normalize_code('NL')
const seed_default_currency_code = normalize_code('EUR')

fn firebird_get_schema_queries() []string {
	queries := schema_file.to_string().split(';')
	return queries[..queries.len - 1] // remove last character \n (posix)
}

fn firebird_get_schema_rollback_queries() []string {
	queries := schema_rollback_file.to_string().split(';')
	return queries[..queries.len - 1] // remove last character \n (posix)
}

fn firebird_get_country_codes() []string {
	country_codes := country_codes_file.to_string().split('\n')
	return country_codes[..country_codes.len - 1] // remove last character \n (posix)
}

fn firebird_get_currency_data() []string {
	currency_codes := currency_file.to_string().split('\n')
	return currency_codes[..currency_codes.len - 1] // remove last character \n (posix)
}

fn firebird_get_locale_codes() []string {
	locale_codes := locale_codes_file.to_string().split('\n')
	return locale_codes[..locale_codes.len - 1] // remove last character \n (posix)
}

fn firebird_insert_country_codes(mut tx firebird.ClientTransaction) ! {
	log.debug('insert_country_codes')
	country_codes := firebird_get_country_codes()
	mut stmt := tx.prepare('INSERT INTO country (code) VALUES (?)')!
	for i := 0; i < country_codes.len; i++ {
		code := normalize_code(country_codes[i])
		stmt.execute(code)!
	}
	stmt.close()!
}

fn firebird_insert_currency_data(mut tx firebird.ClientTransaction) ! {
	log.debug('insert_currency_data')
	currency_data := firebird_get_currency_data()
	mut stmt := tx.prepare('INSERT INTO currency (code, decimal_digits) VALUES (?, ?)')!
	for i := 0; i < currency_data.len; i++ {
		data := currency_data[i].split(',')
		code := normalize_code(data[0])
		decimal_digits_string := data[1]
		decimal_digits := strconv.parse_int(decimal_digits_string, 10, 32) or {
			stmt.execute(code, firebird.Null{})!
			continue
		}
		stmt.execute(code, decimal_digits)!
	}
	stmt.close()!
}

fn firebird_insert_locale_codes(mut tx firebird.ClientTransaction, mut g luuid.Generator) ! {
	log.debug('insert_locale_codes')
	locale_codes := firebird_get_locale_codes()
	mut stmt := tx.prepare('INSERT INTO locale (id, code) VALUES (?, ?)')!
	for i := 0; i < locale_codes.len; i++ {
		id := common.new_id(mut g)
		code := normalize_code(locale_codes[i])
		stmt.execute(id.bytes(), code)!
	}
	stmt.close()!
}

fn firebird_insert_default_user(
	mut tx firebird.ClientTransaction,
	email string,
	password string,
	password_parameters_id common.ID,
	user_id common.ID) ! {
	log.debug('insert_default_user')
	password_hash := hash_password(password)!
	parameters_encoded, parameters_hash := password_hash.parameters.encode()!
	tx.execute('INSERT INTO password_parameters (id, parameters, hash) VALUES (?, ?, ?)',
		password_parameters_id.bytes(), parameters_encoded, parameters_hash)!

	tx.execute('INSERT INTO app_user (id, handle, email, password_hash, password_salt, password_parameters_id, role)
	VALUES (?, ?, ?, ?, ?, ?)',
		user_id.bytes(), user_id.string(), email, password_hash.hash, password_hash.salt,
		password_parameters_id.bytes(), objects.role_admin)!
}

fn firebird_insert_default_region(mut tx firebird.ClientTransaction, region_id common.ID) ! {
	log.debug('insert_default_region')
	tx.execute('INSERT INTO region (id, name, currency_code) VALUES (?, ?, ?)', region_id.bytes(),
		seed_default_region_name, seed_default_currency_code)!
	tx.execute('UPDATE country SET region_id = ?', region_id.bytes())!
}

fn firebird_insert_default_stock_location(mut tx firebird.ClientTransaction, stock_location_id common.ID) ! {
	log.debug('insert_default_stock_location')
	tx.execute('INSERT INTO stock_location (id, name) VALUES (?, ?)', stock_location_id.bytes(),
		seed_default_stock_location_name)!
}

fn firebird_insert_default_sales_channel(mut tx firebird.ClientTransaction, sales_channel_id common.ID) ! {
	log.debug('insert_default_sales_channel')
	tx.execute('INSERT INTO sales_channel (id, name) VALUES (?, ?)', sales_channel_id.bytes(),
		seed_default_sales_channel_name)!
}

fn firebird_insert_default_sales_channel_stock_location(mut tx firebird.ClientTransaction, sales_channel_id common.ID, stock_location_id common.ID) ! {
	log.debug('insert_sales_channel_stock_location')
	tx.execute('INSERT INTO sales_channel_stock_location (sales_channel_id, stock_location_id)
		VALUES (?, ?)',
		sales_channel_id.bytes(), stock_location_id.bytes())!
}

fn firebird_insert_default_api_key(mut tx firebird.ClientTransaction, api_key common.ID, sales_channel_id common.ID) ! {
	log.debug('firebird_insert_default_api_key')
	tx.execute('INSERT INTO api_key (id, name, sales_channel_id) VALUES (?, ?, ?)',
		api_key.bytes(), seed_default_api_key_name, sales_channel_id.bytes())!
}

fn firebird_insert_default_store(mut tx firebird.ClientTransaction, region_id common.ID, store_id common.ID, sales_channel_id common.ID, stock_location_id common.ID) ! {
	log.debug('insert_default_store')
	tx.execute('INSERT INTO store 
		(
			id,
			name,
			default_locale_id,
			default_region_id,
			default_stock_location_id,
			default_sales_channel_id
		)
		VALUES
		(
			?,
			?,
			(SELECT id FROM locale WHERE code = ?),
			?,
			?,
			?
		)',
		store_id.bytes(), seed_default_store_name, seed_default_locale_code, region_id.bytes(),
		stock_location_id.bytes(), sales_channel_id.bytes())!
}

fn firebird_insert_default_store_locale(mut tx firebird.ClientTransaction, store_id common.ID) ! {
	log.debug('insert_default_store_locale')
	tx.execute('INSERT INTO store_locales (store_id, locale_id)
		VALUES (?, (SELECT id FROM locale WHERE code = ?))',
		store_id.bytes(), seed_default_locale_code)!
}

fn firebird_create_schema(mut fbclient firebird.Client) ! {
	log.debug('create_schema')
	schema_queries := firebird_get_schema_queries()
	for i := 0; i < schema_queries.len; i++ {
		q := schema_queries[i].trim_space()
		if q.starts_with('--') { // ignore commented one-liner queries? TODO maybe better check is needed
			continue
		}

		mut tx := fbclient.start_transaction(firebird.isolation_level_read_commited)!
		tx.execute(q) or {
			log.debug('Failed to execute query: ${q}')
			return err
		}
		tx.commit()!
	}
}

fn firebird_rollback_schema(mut fbclient firebird.Client) {
	log.debug('rollback_schema')
	rollback_queries := firebird_get_schema_rollback_queries()
	for i := 0; i < rollback_queries.len; i++ {
		q := rollback_queries[i]

		mut tx := fbclient.start_transaction(firebird.isolation_level_read_commited) or {
			log.debug('Failed to rollback schema. Failed to start transaction. Manual intervention may be required.')
			log.error(err.msg())
			return
		}

		tx.execute(q) or { log.debug('Failed to execute query: ${q}') } // ignore error

		tx.commit() or {
			log.debug('Failed to rollback schema. Failed to commit changes. Manual intervention may be required.')
			log.error(err.msg())
			return
		}
	}
	log.debug('Rollback complete')
}

fn (mut app App) add_data(mut tx firebird.ClientTransaction) ! {
	user_id := app.gen_id()
	password_parameters_id := app.gen_id()
	stock_location_id := app.gen_id()
	region_id := app.gen_id()
	sales_channel_id := app.gen_id()
	api_key_id := app.gen_id()
	store_id := app.gen_id()
	migration_id := app.gen_id()

	firebird_insert_country_codes(mut tx)!
	firebird_insert_currency_data(mut tx)!
	firebird_insert_locale_codes(mut tx, mut app.luuid_generator)!
	firebird_insert_default_user(mut tx, app.config.default_user_email,
		app.config.default_user_password, password_parameters_id, user_id)!
	firebird_insert_default_region(mut tx, region_id)!
	firebird_insert_default_stock_location(mut tx, stock_location_id)!
	firebird_insert_default_sales_channel(mut tx, sales_channel_id)!
	firebird_insert_default_sales_channel_stock_location(mut tx, sales_channel_id,
		stock_location_id)!
	firebird_insert_default_api_key(mut tx, api_key_id, sales_channel_id)!
	firebird_insert_default_store(mut tx, region_id, store_id, sales_channel_id, stock_location_id)!
	firebird_insert_default_store_locale(mut tx, store_id)!
	record.migration_create(mut tx, migration_id, seed_migration_name)!
}

fn (mut app App) is_ready(mut tx firebird.ClientTransaction) !bool {
	migrations := record.migration_retrieve(mut tx) or {
		if err.msg().contains('Table unknown') {
			log.info('Database needs setup: migration table missing')
			return false
		} else {
			log.error('Could not retrieve migrations')
			return err
		}
	}

	for _, migration in migrations {
		if migration.name == seed_migration_name {
			log.info('Store created at ${migration.created_at.Time}')
			return true
		}
	}

	return error('Database contains a migration table, but it lacks a row with name `${seed_migration_name}`.
		Database may be corrupt, manual intervention is required.')
}

// panics on errors
fn (mut app App) prepare_db() ! {
	mut tx := app.start_transaction() or {
		log.error('Failed to start transaction, manual intervention may be required')
		return err
	}

	is_ready := app.is_ready(mut tx)!
	if is_ready {
		tx.rollback() or {}
		return
	}

	log.info('Setting up database')
	firebird_create_schema(mut app.firebird) or {
		log.error('Failed to create schema, rolling back...')
		tx.rollback() or {}
		firebird_rollback_schema(mut app.firebird)
		return err
	}

	app.add_data(mut tx) or {
		log.error('Failed to add default data to database, rolling back...')
		tx.rollback() or { log.error('Failed to rollback transaction') }
		firebird_rollback_schema(mut app.firebird)
		return err
	}

	tx.commit() or {
		log.error('Failed to commit changes to database, manual intervention may be required')
		return err
	}

	log.info('Database setup complete')
}
