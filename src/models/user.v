module models

// vlib
import arrays
import db.mysql as v_mysql
// local
import data.mysql

// Users are either `admin`, `member`, `developer`, `author`, `contributor`
// They are part of the team that runs a peony website.
pub struct User {
pub mut:
	id            string
	handle        string
	email         string
	password_hash string [json: '-']
	role          string
	created_at    string [json: 'createdAt']
	updated_at    string [json: 'updatedAt']
	deleted_at    string [json: 'deletedAt']
	first_name    string [json: 'firstName']
	last_name     string [json: 'lastName']
	metadata      string [raw]
}

// TODO make User immutable
pub struct UserWriteable {
pub mut:
	handle        string
	email         string
	password_hash string [json: '-']
	role          string
	first_name    string [json: 'firstName']
	last_name     string [json: 'lastName']
	metadata      string [raw]
}

// create_user creates a peony user in the database.
// id, email, password_hash and handle are required.
pub fn (uw UserWriteable) create(mut mysql_conn v_mysql.DB, id string) ! {
	mut query_columns := ['id', 'email', 'password_hash', 'handle']
	mut vars := []mysql.Param{}
	vars = arrays.concat(vars, mysql.Param(id), mysql.Param(uw.email), mysql.Param(uw.password_hash),
		mysql.Param(uw.handle))

	// TODO error if id, email, password or handle are missing

	if uw.role != '' {
		if uw.role != 'admin' && uw.role != 'member' && uw.role != 'developer'
			&& uw.role != 'author' && uw.role != 'contributor' {
			return error('user.role must be either "admin", "member", "developer", "author" or "contributor"')
		}
		query_columns = arrays.concat(query_columns, 'role')
		vars = arrays.concat(vars, mysql.Param(uw.role))
	}
	if uw.first_name != '' {
		query_columns = arrays.concat(query_columns, 'first_name')
		vars = arrays.concat(vars, mysql.Param(uw.first_name))
	}
	if uw.last_name != '' {
		query_columns = arrays.concat(query_columns, 'last_name')
		vars = arrays.concat(vars, mysql.Param(uw.last_name))
	}
	if uw.metadata != '' {
		query_columns = arrays.concat(query_columns, 'metadata')
		vars = arrays.concat(vars, mysql.Param(uw.metadata))
	}

	query := 'INSERT INTO "user" (${mysql.columns(query_columns)}) VALUES (UUID_TO_BIN(?, 0), ${mysql.question_marks(query_columns[1..])})'
	mysql.prep_n_exec(mut mysql_conn, 'stmt', query, ...vars)!
}

pub fn (user User) update(mut mysql_conn v_mysql.DB) ! {
	mut query_columns := []string{}
	mut vars := []mysql.Param{}

	if user.handle != '' {
		query_columns = arrays.concat(query_columns, 'handle')
		vars = arrays.concat(vars, mysql.Param(user.handle))
	}
	if user.role != '' {
		query_columns = arrays.concat(query_columns, 'role')
		vars = arrays.concat(vars, mysql.Param(user.role))
	}
	if user.first_name != '' {
		query_columns = arrays.concat(query_columns, 'first_name')
		vars = arrays.concat(vars, mysql.Param(user.first_name))
	}
	if user.last_name != '' {
		query_columns = arrays.concat(query_columns, 'last_name')
		vars = arrays.concat(vars, mysql.Param(user.last_name))
	}
	if user.metadata != '' {
		query_columns = arrays.concat(query_columns, 'metadata')
		vars = arrays.concat(vars, mysql.Param(user.metadata))
	}

	columns_with_question_marks := mysql.columns_with_question_marks(query_columns)

	query := 'UPDATE "user" SET ${columns_with_question_marks}, "updated_at" = NOW() WHERE "id" = ${user.id}' // TODO pass user.id also
	mysql.prep_n_exec(mut mysql_conn, 'stmt', query, ...vars)!
}

// user_retrieve_by_id returns the data of a peony user identified by the provided id.
pub fn user_retrieve_by_id(mut mysql_conn v_mysql.DB, id string) !User {
	// TODO check cache first
	query_columns := ['handle', 'email', 'role', 'created_at', 'updated_at', 'deleted_at',
		'first_name', 'last_name', 'metadata']
	query := 'SELECT ${mysql.columns(query_columns)} FROM "user" WHERE "id" = UUID_TO_BIN(?, 0)'
	res := mysql.prep_n_exec(mut mysql_conn, 'stmt', query, id)!
	row := res.rows()[0].vals

	user := User{
		id: id
		handle: row[0]
		email: row[1]
		role: row[2]
		created_at: row[3]
		updated_at: row[4]
		deleted_at: row[5]
		first_name: row[6]
		last_name: row[7]
		metadata: row[8]
	}
	// TODO add to cache
	return user
}

pub fn user_retrieve_by_email(mut mysql_conn v_mysql.DB, email string) !User {
	query_columns := ['handle', 'email', 'role', 'created_at', 'updated_at', 'deleted_at',
		'first_name', 'last_name', 'metadata']
	query := 'SELECT BIN_TO_UUID("id", 0), ${mysql.columns(query_columns)} FROM "user" WHERE "email" = ?'
	res := mysql.prep_n_exec(mut mysql_conn, 'stmt', query, email)!
	rows := res.rows()
	if rows.len == 0 {
		return error('No matching user with email ${email}')
	}
	vals := rows[0].vals

	user := User{
		id: vals[0]
		handle: vals[1]
		email: vals[2]
		role: vals[3]
		created_at: vals[4]
		updated_at: vals[5]
		deleted_at: vals[6]
		first_name: vals[7]
		last_name: vals[8]
		metadata: vals[9]
	}
	return user
}

pub fn user_password_hash_by_email(mut mysql_conn v_mysql.DB, email string) !string {
	query := 'SELECT "password_hash" FROM "user" WHERE "email" = ?'
	res := mysql.prep_n_exec(mut mysql_conn, 'stmt', query, email)!
	rows := res.rows()
	if rows.len == 0 {
		return error('No email')
	}
	return rows[0].vals[0]
}

pub fn user_delete_by_id(mut mysql_conn v_mysql.DB, id string) ! {
	query := '
	UPDATE "user" 
	SET "deleted_at" = NOW() 
	WHERE "id" = UUID_TO_BIN(?)'
	mysql.prep_n_exec(mut mysql_conn, 'stmt', query, id)!
}

// user_list returns an array of all peony users.
pub fn user_list(mut mysql_conn v_mysql.DB) ![]User {
	query_columns := ['handle', 'email', 'role', 'created_at', 'updated_at', 'deleted_at',
		'first_name', 'last_name', 'metadata']
	query := 'SELECT BIN_TO_UUID("id"), ${mysql.columns(query_columns)} FROM "user"'
	res := mysql.prep_n_exec(mut mysql_conn, 'stmt', query)!

	rows := res.rows()
	mut users := []User{}

	for row in rows {
		vals := row.vals
		mut user := User{
			id: vals[0]
			handle: vals[1]
			email: vals[2]
			role: vals[3]
			created_at: vals[4]
			updated_at: vals[5]
			deleted_at: vals[6]
			first_name: vals[7]
			last_name: vals[8]
			metadata: vals[9]
		}
		users = arrays.concat(users, user)
	}
	return users
}

/*
*
* author
*
*/

// user_list_authors returns an array of peony users that have posts associated with them.
// TODO rewrite and rename
pub fn user_list_authors(mut mysql_conn v_mysql.DB) ![]User {
	query_columns := ['handle', 'email', 'role', 'created_at', 'updated_at', 'deleted_at',
		'first_name', 'last_name', 'metadata']
	// TODO test ambiguous id
	qua_cols := mysql.qualified_columns(query_columns, 'user')
	query := 'SELECT DISTINCT BIN_TO_UUID("user"."id", 0), ${qua_cols} FROM "user" INNER JOIN "post" ON "user"."id" = "post"."published_by"'
	res := mysql.prep_n_exec(mut mysql_conn, 'stmt', query)!

	rows := res.rows()
	mut users := []User{}

	for row in rows {
		vals := row.vals
		mut user := User{
			id: vals[0]
			handle: vals[1]
			email: vals[2]
			role: vals[3]
			created_at: vals[4]
			updated_at: vals[5]
			deleted_at: vals[6]
			first_name: vals[7]
			last_name: vals[8]
			metadata: vals[9]
		}
		users = arrays.concat(users, user)
	}
	return users
}

// TODO rewrite and rename
pub fn user_retrieve_author_by_id(mut mysql_conn v_mysql.DB, id int) ![]User {
	query_columns := ['handle', 'email', 'role', 'created_at', 'updated_at', 'deleted_at',
		'first_name', 'last_name', 'metadata']
	qua_cols := mysql.qualified_columns(query_columns, 'user')
	query := 'SELECT DISTINCT BIN_TO_UUID("user"."id"), ${qua_cols} FROM "user" INNER JOIN "post" ON "user"."id" = "post"."published_by" WHERE "user"."id" = ?'
	res := mysql.prep_n_exec(mut mysql_conn, 'stmt', query, id)!

	rows := res.rows()
	mut users := []User{}

	for row in rows {
		vals := row.vals
		mut user := User{
			id: vals[0]
			handle: vals[1]
			email: vals[2]
			role: vals[3]
			created_at: vals[4]
			updated_at: vals[5]
			deleted_at: vals[6]
			first_name: vals[7]
			last_name: vals[8]
			metadata: vals[9]
		}
		users = arrays.concat(users, user)
	}
	return users
}

pub fn authors_retrieve_by_post_id(mut mysql_conn v_mysql.DB, post_id string) ![]User {
	// TODO check cache
	query := '
		SELECT BIN_TO_UUID("author_id")
		FROM "post_authors" 
		WHERE "post_id" = UUID_TO_BIN(?)'

	res := mysql.prep_n_exec(mut mysql_conn, 'stmt', query, post_id)!

	rows := res.rows()
	mut author_ids := []string{}

	for row in rows {
		vals := row.vals
		author_ids = arrays.concat(author_ids, vals[0])
	}

	mut users := []User{}
	for author_id in author_ids {
		user := user_retrieve_by_id(mut mysql_conn, author_id)!
		users = arrays.concat(users, user)
	}

	// TODO add to cache
	return users
}

// TODO functions to add and remove authors
