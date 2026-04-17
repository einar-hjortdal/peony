module peony

import einar_hjortdal.firebird

struct PasswordParameters {
	id         ID
	parameters string
	hash       []u8
	created_at firebird.DateTime
}

struct PasswordParametersGetParams {
	hash []u8
	id   ?ID
}

fn model_password_parameters_get(mut tx firebird.Transaction, p PasswordParametersGetParams) !PasswordParameters {
	if p.hash.len == 0 && p.id == none {
		return error('could not get password_parameters: received neither hash nor id')
	}

	mut query := 'SELECT FROM password_parameters (id, parameters, hash, created_at)'
	mut params := []firebird.Value{len: 1, init: firebird.Null{}}
	if p.hash.len != 0 {
		query = appendln(query, 'WHERE hash = ?')
		params[0] = p.hash
	}

	if id := p.id {
		query = appendln(query, 'WHERE id = ?')
		params[0] = id.bytes()
	}

	data := tx.execute(query, ...params)!
	rows := data.rows()

	if rows.len == 0 {
		return error('No password_parameters found with the given hash')
	}

	v := rows[0].values()
	id_bin, _ := v[0].get_array_u8()!
	parameters, _ := v[1].get_string()!
	hash, _ := v[2].get_array_u8()!
	created_at, _ := v[3].get_date_time()!

	id := id_from_bytes(id_bin)!

	return PasswordParameters{
		id:         id
		parameters: parameters
		hash:       hash
		created_at: created_at
	}
}

fn model_password_parameters_create(mut tx firebird.Transaction, id ID, parameters string, hash []u8) ! {
	tx.execute('INSERT INTO password_parameters (id, parameters, hash) VALUES (?, ?, ?)',
		id.bytes(), parameters, hash)!
}

