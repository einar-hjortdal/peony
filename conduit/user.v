module conduit

import log
import veb
import einar_hjortdal.firebird
import record

pub const role_admin = record.role_admin
pub const role_member = record.role_member
pub const role_developer = record.role_developer
pub const role_author = record.role_author
pub const role_contributor = record.role_contributor

pub type User = record.User

pub type UserCreateRequest = record.UserCreateRequest

pub fn user_create(mut tx firebird.Transaction, user_id ID, p UserCreateRequest) ! {
	password_hash := hash_password(p.password) or {
		perr := new_error_internal('Failed hash password', err.msg())
		return ctx.handle_error(perr)
	}
	password_parameters_encoded, password_parameters_hash := password_hash.parameters.encode() or {
		return new_error_internal('Failed to encode password_parameters', err.msg())
	}
	user_id := app.gen_id()

	password_details := record.password_details_get(mut tx, record.PasswordDetailsGetParams{
		hash: password_parameters_hash
	}) or {
		password_parameters_id := app.gen_id()
		record.password_details_create(mut tx, password_parameters_id, argon2id_name,
			password_parameters_encoded, password_parameters_hash) or {
			tx.rollback() or {}
			return ctx.handle_error(err)
		}

		record.password_details_get(mut tx, PasswordDetailsGetParams{
			hash: password_parameters_hash
		}) or {
			return ctx.handle_error(err)
		}
	}

	if image := p.image {
		println('TODO create image: ${image}')
	}

	record.user_create(mut tx, UserCreateParams{
		user_id:                user_id
		handle:                 user_id.string() // TODO validate and format in route
		email:                  p.email
		password_hash:          password_hash.hash
		password_salt:          password_hash.salt
		password_parameters_id: password_details.id
		role:                   unwrap_option_or(p.role, role_admin) // TODO validate and format in route
		first_name:             p.first_name
		last_name:              p.last_name
		// image_id
		metadata: p.metadata
	}) or {
		return  new_error_internal('Failed to create user', err.msg())
	}

}

pub type UserUpdateRequest = record.UserUpdateRequest

pub fn user_update(mut tx firebird.Transaction, user_id ID, p UserUpdateRequest) ! {
	// TODO password
	if image := p.image {
		println('TODO update image: ${image}')
	}

	record.user_update(mut tx, user_id, p) or {
		return new_error_internal('Failed to create user', err.msg())
	}
}

pub fn user_delete(mut tx firebird.Transaction, user_id ID) ! {
	record.user_delete(mut tx, user_id_bin) or {
		return new_error_internal('Failed to delete user', err.msg())
	}

}

pub type UserListParams = record.UserListParams

pub fn user_list_count(mut tx firebird.Transaction, p UserListParams) !i64{
	count := record.user_retrieve_count(mut tx, p) or {
		return new_error_internal('Failed to retrieve user count', err.msg())
	}
	return count
}

pub fn user_list(mut tx firebird.Transaction, p UserListParams) ![]User {
	users := record.user_list(mut tx, p) or {
		return  new_error_internal('Failed to retrieve users', err.msg())
	}
	return users
}

pub fn user_get_by_id(mut tx firebird.Transaction, user_id ID) !User {
	users := record.user_list(mut tx, UserListParams{
		ids:   [user_id]
		offset: default_offset
		fetch: 1
		order: order_default

	}) or {
		return new_error_internal('Failed to retrieve users', err.msg())
	}

	if users.len == 0 {
		return new_error_not_found('user not found','No user exists with id `${user.id.string()}`')
	}

	user := users[0]
	return user
}

pub fn user_get_by_email(mut app App, mut tx firebird.Transaction, email string) !User {
	users := record.user_list(mut tx, UserListParams{
		email:   email
		offset: default_offset
		fetch: 1
		order: order_default
	}) or {
		return new_error_internal('Failed to retrieve users', err.msg())
	}

	if users.len == 0 {
		return new_error_not_found('user not found','No user exists with email `${email}`')
	}

	user := users[0]
	return user
}
 
