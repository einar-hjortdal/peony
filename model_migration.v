module peony

import einar_hjortdal.firebird

struct Migration {
	id         string
	id_bin     []u8 @[json: '-']
	created_at firebird.DateTime
	name       string
}

fn parse_migration(v []firebird.Value) !Migration {
	id_bin, _ := v[0].get_array_u8()!
	created_at, _ := v[1].get_date_time()!
	name, _ := v[2].get_string()!

	id := id_bin_to_string(id_bin)!

	return Migration{
		id:         id
		id_bin:     id_bin
		created_at: created_at
		name:       name
	}
}

fn (mut app App) do_create_migration(mut tx firebird.Transaction, name string) ! {
	_, id_bin := app.new_id()
	tx.execute('INSERT INTO migration (id, name) VALUES (?, ?)', id_bin, name)!
}

fn (mut app App) retrieve_migrations() ![]Migration {
	mut tx := app.start_transaction()!
	data := tx.execute('SELECT id, created_at, name FROM migration')!
	tx.rollback()!
	rows := data.rows()

	mut migrations := []Migration{len: rows.len}
	for i := 0; i < rows.len; i++ {
		migrations[i] = parse_migration(rows[i].values())!
	}
	return migrations
}

fn find_migration(m []Migration, name string) ?Migration {
	for i := 0; i < m.len; i++ {
		if m[i].name == name {
			return m[i]
		}
	}
	return none
}
