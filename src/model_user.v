module main

import arrays
import einar_hjortdal.firebird

const role_admin = 'admin'
const role_member = 'member'
const role_developer = 'developer'
const role_author = 'author'
const role_contributor = 'contributor'

struct User {
	id            string
	id_bin        []u8 @[json: '-']
	handle        string
	email         string
	password_hash []u8
	password_salt []u8
	role          string
	created_at    firebird.DateTime
	updated_at    firebird.DateTime
	deleted_at    firebird.DateTime @[omitempty]
	first_name    string            @[omitempty]
	last_name     string            @[omitempty]
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
	}
}

struct NewUserData {
	email      string
	password   string
	first_name string @[omitempty]
	last_name  string @[omitempty]
	role       string @[omitempty]
}

fn (mut app App) create_user(d NewUserData) !string {
	id := app.luuid_generator.v1()
	handle := app.luuid_generator.v1()
	password_hash, password_salt := hash_password(d.password)!

	mut c := ['handle', 'email', 'password_hash', 'password_salt']
	mut params := [firebird.Value(handle), d.email, password_hash, password_salt]
	if d.role != '' {
		c = arrays.concat(c, 'role')
		params = arrays.concat(params, d.role)
	}
	if d.first_name != '' {
		c = arrays.concat(c, 'first_name')
		params = arrays.concat(params, d.first_name)
	}
	if d.last_name != '' {
		c = arrays.concat(c, 'last_name')
		params = arrays.concat(params, d.last_name)
	}

	mut tx := app.fb.start_transaction(firebird.isolation_level_read_commited)!
	tx.execute('INSERT INTO user (
		id,
		handle,
		email,
		password_hash,
		password_salt,
		role,
		first_name,
		last_name
		)	VALUES (CHAR_TO_UUID(?), ${get_columns(c)})',
		arrays.concat([firebird.Value(id)], params))!
	tx.commit()!

	return id
}

fn (mut app App) retrieve_user_by_id(id string) !User {
	mut tx := app.fb.start_transaction(firebird.isolation_level_read_commited)!
	res := tx.execute('SELECT (
		UUID_TO_CHAR(id),
		handle,
		email,
		password_hash,
		password_salt,
		role,
		first_name,
		last_name
		)	FROM user WHERE id = CHAR_TO_UUID(?)',
		id)!
	tx.rollback()!

	if res.rows.len == 0 {
		return error(format_error_message('No user found'))
	}

	return parse_user_data(res.rows[0].values)!
}

fn (mut app App) retrieve_user_by_email(email string) !User {
	mut tx := app.fb.start_transaction(firebird.isolation_level_read_commited)!
	res := tx.execute('SELECT (
		UUID_TO_CHAR(id),
		handle,
		email,
		password_hash,
		password_salt,
		role,
		first_name,
		last_name
		)	FROM user WHERE email = ?',
		email)!
	tx.rollback()!

	if res.rows.len == 0 {
		return error(format_error_message('No user found'))
	}

	return parse_user_data(res.rows[0].values)!
}

struct UpdateUserData {
	first_name string
	last_name  string
	role       string
}

fn (mut app App) update_user(id string, data UpdateUserData) ! {
	mut tx := app.fb.start_transaction(firebird.isolation_level_read_commited)!
	tx.execute('UPDATE user SET
		first_name = ?,
		last_name = ?,
		role = ?
		WHERE id = CHAR_TO_UUID(?)',
		data.first_name, data.last_name, data.role, id)!
	tx.commit()!
}

fn (mut app App) delete_user(id string) ! {
	mut tx := app.fb.start_transaction(firebird.isolation_level_read_commited)!
	tx.execute('UPDATE user SET deleted_at = CURRENT_TIMESTAMP WHERE id = CHAR_TO_UUID(?)',
		id)!
	tx.commit()!
}
