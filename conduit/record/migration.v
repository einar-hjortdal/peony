module record

import einar_hjortdal.firebird

pub struct Migration {
pub:
	id         ID
	created_at firebird.DateTime
	name       string
}

pub fn migration_create(mut tx firebird.Transaction, migration_id ID, name string) ! {
	tx.execute('INSERT INTO migration (id, name) VALUES (?, ?)', migration_id.bytes(), name)!
}

pub fn migration_retrieve(mut tx firebird.Transaction) ![]Migration {
	data := tx.execute('SELECT id, created_at, name FROM migration ORDER BY created_at ASC')!
	rows := data.rows()
	mut migrations := []Migration{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()
		id_bin, _ := v[0].get_array_u8()!
		created_at, _ := v[1].get_date_time()!
		name, _ := v[2].get_string()!

		id := id_from_bytes(id_bin)!

		migrations[i] = Migration{
			id:         id
			created_at: created_at
			name:       name
		}
	}
	return migrations
}

