module main

import einar_hjortdal.firebird

const role_admin = 'admin'
const role_member = 'member'
const role_developer = 'developer'
const role_author = 'author'
const role_contributor = 'contributor'

fn is_valid_role(s string) bool {
	return s == role_admin || s == role_member || s == role_developer || s == role_author
		|| s == role_contributor
}

struct User {
	id            string
	handle        string
	email         string
	password_hash []u8
	password_salt []u8
	role          string
	created_at    firebird.DateTime
	updated_at    firebird.DateTime
	deleted_at    firebird.NullDateTime
	first_name    firebird.NullString
	last_name     firebird.NullString
}

fn parse_user_data(v []firebird.Value) !User {
	id, _ := firebird.get_string(v[0])!
	handle, _ := firebird.get_string(v[1])!
	email, _ := firebird.get_string(v[2])!
	password_hash, _ := firebird.get_array_u8(v[3])!
	password_salt, _ := firebird.get_array_u8(v[4])!
	role, _ := firebird.get_string(v[5])!
	created_at, _ := firebird.get_date_time(v[6])!
	updated_at, _ := firebird.get_date_time(v[7])!
	deleted_at := firebird.get_null_date_time(v[8])!
	first_name := firebird.get_null_string(v[9])!
	last_name := firebird.get_null_string(v[10])!

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
	first_name string
	last_name  string
	role       string
}

fn (mut app App) create_user(d NewUserData) !string {
	id := app.luuid_generator.v1()
	handle := app.luuid_generator.v1()
	password_hash, password_salt := hash_password(d.password)!

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
		)	VALUES (CHAR_TO_UUID(?), ?, ?, ?, ?, ?, ?, ?)',
		id, handle, d.email, password_hash, password_salt, d.role, d.first_name, d.last_name)!
	tx.commit()!

	return id
}

fn (mut app App) retrieve_user(id string) !User {
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
