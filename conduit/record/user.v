module record

import arrays
import einar_hjortdal.firebird

pub const role_admin = 'admin'
pub const role_member = 'member'
pub const role_developer = 'developer'
pub const role_author = 'author'
pub const role_contributor = 'contributor'

pub struct User {
	id                     ID
	handle                 string
	email                  string
	password_hash          []u8
	password_salt          []u8
	password_parameters_id ID
	role                   string
	created_at             firebird.DateTime
	updated_at             firebird.DateTime
	deleted_at             firebird.DateTime
	first_name             string
	last_name              string
	metadata               firebird.NullString
mut:
	image UserImage
}

pub fn (u User) id() ID {
	return u.id
}

pub struct UserCreateParams {
	user_id                ID
	handle                 string
	email                  string
	password_hash          []u8
	password_salt          []u8
	password_parameters_id ID
	role                   string
	first_name             ?string
	last_name              ?string
	image_id               ?ID
	metadata               ?string
}

pub fn user_create(mut tx firebird.Transaction, p UserCreateParams) ! {
	mut c := [
		'id',
		'handle',
		'email',
		'password_hash',
		'password_salt',
		'password_parameters_id',
		'role',
	]

	mut params := [
		firebird.Value(p.user_id.bytes()),
		p.handle,
		p.email,
		p.password_hash,
		p.password_salt,
		p.password_parameters_id.bytes(),
		p.role,
	]

	if first_name := p.first_name {
		c = arrays.concat(c, 'first_name')
		params = arrays.concat(params, first_name)
	}

	if last_name := p.last_name {
		c = arrays.concat(c, 'last_name')
		params = arrays.concat(params, last_name)
	}

	if metadata := p.metadata {
		c = arrays.concat(c, 'metadata')
		params = arrays.concat(params, metadata)
	}

	tx.execute('INSERT INTO app_user (${get_columns(c)}) VALUES (${get_placeholders(c)})',
		...params)!
}

pub struct UserListParams {
pub:
	ids          ?[]ID
	handle       ?string
	email        ?string
	roles        ?[]string
	with_deleted bool
	offset       i32
	fetch        i32
	order        string
}

pub fn user_list_conditions(p UserListParams) (string, []firebird.Value) {
	mut conditions := []string{}
	mut params := []firebird.Value{}

	if ids := p.ids {
		conditions = arrays.concat(conditions, 'id IN (${get_placeholders(ids)})')
		params = arrays.concat(params, ...ids_bytes(ids))
	}

	if handle := p.handle {
		conditions = arrays.concat(conditions, 'handle = ?')
		params = arrays.concat(params, handle)
	}

	if email := p.email {
		conditions = arrays.concat(conditions, 'email = ?')
		params = arrays.concat(params, email)
	}

	if roles := p.roles {
		conditions = arrays.concat(conditions, 'role IN (${get_placeholders(roles)})')
		params = arrays.concat(params, ...roles)
	}

	if !p.with_deleted {
		conditions = arrays.concat(conditions, 'deleted_at IS NULL')
	}

	return get_where_conditions(conditions), params
}

pub fn user_list_count(mut tx firebird.Transaction, p UserListParams) !i64 {
	conditions, params := user_list_conditions(p)
	query := 'SELECT COUNT(*) FROM app_user ${conditions}'
	data := tx.execute(query, ...params)!
	rows := data.rows()
	values := rows[0].values() // should always return one row
	count, _ := values[0].get_i64()! // should always return one column
	return count
}

pub fn user_list(mut tx firebird.Transaction, p UserListParams) ![]User {
	conditions, mut params := user_list_conditions(p)

	mut sorting := 'ORDER BY created_at ${p.order} 
		OFFSET ? ROWS
		FETCH NEXT ? ROWS ONLY'
	params = arrays.concat(params, p.offset, p.fetch)

	query := 'SELECT
		id,
		handle,
		email,
		password_hash,
		password_salt,
		password_parameters_id,
		role,
		created_at,
		updated_at,
		deleted_at,
		first_name,
		last_name,
		metadata
		FROM app_user ${conditions} ${sorting}'

	data := tx.execute(query, ...params)!

	rows := data.rows()
	mut users := []User{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()

		id_bin, _ := v[0].get_array_u8()!
		handle, _ := v[1].get_string()!
		email, _ := v[2].get_string()!
		password_hash, _ := v[3].get_array_u8()!
		password_salt, _ := v[4].get_array_u8()!
		password_parameters_id_bin, _ := v[5].get_array_u8()!
		role, _ := v[6].get_string()!
		created_at, _ := v[7].get_date_time()!
		updated_at, _ := v[8].get_date_time()!
		deleted_at, _ := v[9].get_date_time()!
		first_name, _ := v[10].get_string()!
		last_name, _ := v[11].get_string()!
		metadata := v[12].get_null_string()!

		id := id_from_bytes(id_bin)!
		password_parameters_id := id_from_bytes(password_parameters_id_bin)!

		users[i] = User{
			id:                     id
			handle:                 handle
			email:                  email
			password_hash:          password_hash
			password_salt:          password_salt
			password_parameters_id: password_parameters_id
			role:                   role
			created_at:             created_at
			updated_at:             updated_at
			deleted_at:             deleted_at
			first_name:             first_name
			last_name:              last_name
			metadata:               metadata
		}
	}

	return users
}

pub struct UserUpdateParams {
pub:
	email      ?string
	first_name ?string
	last_name  ?string
	role       ?string
	metadata   ?string
}

// TODO handle password
// TODO validate params
pub fn user_update(mut tx firebird.Transaction, user_id ID, p UserUpdateParams) ! {
	mut columns := []string{}
	mut params := []firebird.Value{}

	if email := p.email {
		columns = arrays.concat(columns, 'email')
		params = arrays.concat(params, email)
	}

	if first_name := p.first_name {
		columns = arrays.concat(columns, 'first_name')
		if first_name == '' {
			params = arrays.concat(params, firebird.Null{})
		} else {
			params = arrays.concat(params, first_name)
		}
	}

	if last_name := p.last_name {
		columns = arrays.concat(columns, 'last_name')
		if last_name == '' {
			params = arrays.concat(params, firebird.Null{})
		} else {
			params = arrays.concat(params, last_name)
		}
	}

	if role := p.role {
		columns = arrays.concat(columns, 'role')
		params = arrays.concat(params, role)
	}

	if metadata := p.metadata {
		columns = arrays.concat(columns, 'metadata')
		params = arrays.concat(params, metadata)
	}

	params = arrays.concat(params, user_id.bytes())

	tx.execute('UPDATE app_user SET (${get_set_columns_with_updated_at(columns)}) WHERE id = ?',
		...params)!
}

pub fn user_delete(mut tx firebird.Transaction, user_id ID) ! {
	tx.execute('UPDATE app_user SET deleted_at = CURRENT_TIMESTAMP WHERE id = ?', user_id.bytes())!
}

