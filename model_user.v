module main

import arrays
import einar_hjortdal.firebird

const role_admin = 'admin'
const role_member = 'member'
const role_developer = 'developer'
const role_author = 'author'
const role_contributor = 'contributor'

// For internal use only: send UserResponse over the network
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
	first_name ?string
	last_name  ?string
	role       ?string
}

fn (mut app App) create_user(d NewUserData) !(string, []u8) {
	id, id_bin := app.new_id()!
	handle := app.luuid_generator.v1()
	password_hash, password_salt := hash_password(d.password)!

	mut c := ['id', 'handle', 'email', 'password_hash', 'password_salt']
	mut params := [firebird.Value(id_bin), handle, d.email, password_hash, password_salt]

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

	mut tx := app.start_transaction()!
	tx.execute('INSERT INTO app_user (
		id,
		handle,
		email,
		password_hash,
		password_salt,
		role,
		first_name,
		last_name
		) VALUES ${get_columns(c)})',
		arrays.concat([firebird.Value(id)], params))!
	tx.commit()!

	return id, id_bin
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
		last_name
		FROM app_user WHERE id = ?',
		id_bin)!
	tx.rollback()!

	if res.rows.len == 0 {
		return error(format_error_message('No app_user found'))
	}

	return parse_user_data(res.rows[0].values)!
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
		last_name
		FROM app_user WHERE email = ?',
		email)!
	tx.rollback()!

	if res.rows.len == 0 {
		return error(format_error_message('No app_user found'))
	}

	return parse_user_data(res.rows[0].values)!
}

struct UpdateUserData {
	first_name ?string
	last_name  ?string
	role       ?string
}

fn (mut app App) update_user(id_bin []u8, p UpdateUserData) ! {
	mut query := 'UPDATE app_user SET'
	mut params := []firebird.Value{}

	if first_name := p.first_name {
		query = appendln(query, 'first_name = ?')
		params = arrays.concat(params, first_name)
	}

	if last_name := p.last_name {
		query = appendln(query, 'last_name = ?')
		params = arrays.concat(params, last_name)
	}

	if role := p.role {
		query = appendln(query, 'role = ?')
		params = arrays.concat(params, role)
	}

	conditions := 'WHERE id = ?'
	query = appendln(query, conditions)
	params = arrays.concat(params, id_bin)

	mut tx := app.start_transaction()!
	tx.execute(query, ...params)!
	tx.commit()!
}

fn (mut app App) delete_user(id_bin []u8) ! {
	mut tx := app.start_transaction()!
	tx.execute('UPDATE app_user SET deleted_at = CURRENT_TIMESTAMP WHERE id = ?', id_bin)!
	tx.commit()!
}
