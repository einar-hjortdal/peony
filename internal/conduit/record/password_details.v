module record

import einar_hjortdal.firebird
import internal.common

pub struct PasswordDetails {
pub:
	id            common.ID
	function_name string
	parameters    string
	hash          []u8
	created_at    firebird.DateTime
}

pub fn (p PasswordDetails) id() common.ID {
	return p.id
}

// a password_details row can be identified by its id or the hash of function name and its parameters
pub struct PasswordDetailsGetParams {
pub:
	hash ?[]u8
	id   ?common.ID
}

pub fn password_details_get(mut tx firebird.ClientTransaction, p PasswordDetailsGetParams) !PasswordDetails {
	if p.hash == none && p.id == none {
		return error('could not get password_details: received neither hash nor id')
	}

	mut query := 'SELECT id, function_name, parameters, hash, created_at FROM password_details'
	mut params := []firebird.Value{len: 0, cap: 1, init: firebird.Null{}}

	if hash := p.hash {
		query = appendln(query, 'WHERE hash = ?')
		params << hash
	}

	if id := p.id {
		query = appendln(query, 'WHERE id = ?')
		params << id.bytes()
	}

	data := tx.execute(query, ...params)!
	rows := data.rows()

	if rows.len == 0 {
		return error('No password_details found with the given hash')
	}

	v := rows[0].values()
	id_bin, _ := v[0].get_array_u8()!
	function_name, _ := v[1].get_string()!
	parameters, _ := v[2].get_string()!
	hash, _ := v[3].get_array_u8()!
	created_at, _ := v[4].get_date_time()!

	id := common.id_from_bytes(id_bin)!

	return PasswordDetails{
		id:            id
		function_name: function_name
		parameters:    parameters
		hash:          hash
		created_at:    created_at
	}
}

pub fn password_details_create(mut tx firebird.ClientTransaction, id common.ID, function_name string, parameters string, hash []u8) ! {
	tx.execute('INSERT INTO password_details (id, function_name, parameters, hash) VALUES (?, ?, ?, ?)',
		id.bytes(), function_name, parameters, hash)!
}
