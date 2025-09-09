module peony

import arrays
import einar_hjortdal.firebird

const role_admin = 'admin'
const role_member = 'member'
const role_developer = 'developer'
const role_author = 'author'
const role_contributor = 'contributor'

struct User {
	id            string
	id_bin        []u8
	handle        string
	email         string
	password_hash []u8
	password_salt []u8
	role          string
	created_at    firebird.DateTime
	updated_at    firebird.DateTime
	deleted_at    firebird.DateTime
	first_name    string
	last_name     string
	metadata      firebird.NullString
}

fn parse_user_data(v []firebird.Value) !User {
	id_bin, _ := v[0].get_array_u8()!
	handle, _ := v[1].get_string()!
	email, _ := v[2].get_string()!
	password_hash, _ := v[3].get_array_u8()!
	password_salt, _ := v[4].get_array_u8()!
	role, _ := v[5].get_string()!
	created_at, _ := v[6].get_date_time()!
	updated_at, _ := v[7].get_date_time()!
	deleted_at, _ := v[8].get_date_time()!
	first_name, _ := v[9].get_string()!
	last_name, _ := v[10].get_string()!

	id := id_bin_to_string(id_bin)!

	return User{
		id:            id
		id_bin:        id_bin
		handle:        handle
		email:         email
		password_hash: password_hash
		password_salt: password_salt
		role:          role
		created_at:    created_at
		updated_at:    updated_at
		deleted_at:    deleted_at
		first_name:    first_name
		last_name:     last_name
		metadata:      v[11].get_null_string()!
	}
}

fn model_user_create(mut tx firebird.Transaction, d NewUserData, id string, id_bin []u8) ! {
	password_hash, password_salt := hash_password(d.password)!

	mut c := ['id', 'handle', 'email', 'password_hash', 'password_salt']
	mut params := [firebird.Value(id_bin), id, d.email, password_hash, password_salt]

	if role := d.role {
		c = arrays.concat(c, 'role')
		params = arrays.concat(params, role)
	}

	if first_name := d.first_name {
		c = arrays.concat(c, 'first_name')
		params = arrays.concat(params, first_name)
	}

	if last_name := d.last_name {
		c = arrays.concat(c, 'last_name')
		params = arrays.concat(params, last_name)
	}

	if metadata := d.metadata {
		c = arrays.concat(c, 'metadata')
		params = arrays.concat(params, metadata)
	}

	tx.execute('INSERT INTO app_user (${get_columns(c)}) VALUES (${get_placeholders(c)})',
		arrays.concat([firebird.Value(id)], params))!
}

fn (mut app App) retrieve_user_by_id(id_bin []u8) !User {
	mut tx := app.start_transaction()!
	res := tx.execute('SELECT
		id,
		handle,
		email,
		password_hash,
		password_salt,
		role,
		created_at,
		updated_at,
		deleted_at,
		first_name,
		last_name,
		metadata
		FROM app_user WHERE id = ?',
		id_bin)!
	tx.rollback()!

	rows := res.rows()
	if rows.len == 0 {
		return error(format_error_message('No app_user found'))
	}

	return parse_user_data(rows[0].values())!
}

fn (mut app App) retrieve_user_by_email(email string) !User {
	mut tx := app.start_transaction()!
	res := tx.execute('SELECT
		id,
		handle,
		email,
		password_hash,
		password_salt,
		role,
		created_at,
		updated_at,
		deleted_at,
		first_name,
		last_name,
		metadata
		FROM app_user WHERE email = ?',
		email)!
	tx.rollback()!

	rows := res.rows()
	if rows.len == 0 {
		return error(format_error_message('No app_user found'))
	}

	return parse_user_data(rows[0].values())!
}

fn model_user_update(mut tx firebird.Transaction, id_bin []u8, p UpdateUserData) ! {
	mut columns := []string{}
	mut params := []firebird.Value{}

	if first_name := p.first_name {
		columns = arrays.concat(columns, 'first_name')
		params = arrays.concat(params, first_name)
	}

	if last_name := p.last_name {
		columns = arrays.concat(columns, 'last_name')
		params = arrays.concat(params, last_name)
	}

	if role := p.role {
		columns = arrays.concat(columns, 'role')
		params = arrays.concat(params, role)
	}

	if metadata := p.metadata {
		columns = arrays.concat(columns, 'metadata')
		params = arrays.concat(params, metadata)
	}

	params = arrays.concat(params, id_bin)

	tx.execute('UPDATE app_user SET (${get_set_columns_with_updated_at(columns)}) WHERE id = ?',
		...params)!
}

fn model_user_delete(mut tx firebird.Transaction, id_bin []u8) ! {
	tx.execute('UPDATE app_user SET deleted_at = CURRENT_TIMESTAMP WHERE id = ?', id_bin)!
}
