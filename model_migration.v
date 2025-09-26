module peony

import einar_hjortdal.firebird

struct Migration {
	id         string
	id_bin     []u8 @[json: '-']
	created_at firebird.DateTime
	name       string
}

fn model_migration_create(mut tx firebird.Transaction, migration_id_bin []u8, name string) ! {
	tx.execute('INSERT INTO migration (id, name) VALUES (?, ?)', migration_id_bin, name)!
}

fn (mut app App) retrieve_migrations() ![]Migration {
	mut tx := app.start_transaction()!
	data := tx.execute('SELECT id, created_at, name FROM migration')!
	tx.rollback()!
	rows := data.rows()

	mut migrations := []Migration{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()
		id_bin, _ := v[0].get_array_u8()!
		created_at, _ := v[1].get_date_time()!
		name, _ := v[2].get_string()!

		id := id_bin_to_string(id_bin)!

		migrations[i] = Migration{
			id:         id
			id_bin:     id_bin
			created_at: created_at
			name:       name
		}
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
