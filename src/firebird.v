module main

// import arrays
// import log
import os
import einar_hjortdal.luuid
import einar_hjortdal.firebird

const migrations_path = './migrations/'
const schema = '${migrations_path}seed-schema.sql'
const country_codes = '${migrations_path}seed-country-codes.txt'
const currency_codes = '${migrations_path}seed-currency-codes.txt'
const locale_codes = '${migrations_path}seed-locale-codes.txt'

fn database_is_ready(mut conn firebird.Connection) bool {
	// assume the database is ready if get_store_data does not fail
	if _ := get_store_data(mut conn) {
		return true
	} else {
		return false
	}
}

fn create_schema(mut conn firebird.Connection) ! {
	file := os.read_file(schema)!
	commands := file.split(';')
	for i := 0; i < commands.len; i++ {
		c := commands[i]
		mut tx := conn.start_transaction(firebird.isolation_level_read_commited)!
		tx.execute(c)!
		tx.commit()!
	}
}

fn add_data(mut conn firebird.Connection, mut gen luuid.Generator) ! {
	country_codes_file := os.read_file(country_codes)!
	country_codes_lines := country_codes_file.split('\n')

	mut tx := conn.start_transaction(firebird.isolation_level_read_commited)!
	mut stmt := tx.prepare('INSERT INTO country (id, code) VALUES (?, ?)')!
	for i := 0; i < country_codes_lines.len; i++ {
		id := gen.v1()
		code := country_codes_lines[i]
		stmt.execute(id, code)!
	}

	// TODO currency and locale
	stmt.close()!
	tx.commit()!
}

fn prepare_db(mut conn firebird.Connection, mut gen luuid.Generator) ! {
	if database_is_ready(mut conn) {
		return
	}
	create_schema(mut conn)!
	add_data(mut conn, mut gen)!
}
