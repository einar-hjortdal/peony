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

// TODO create image
pub fn user_create(mut tx firebird.Transaction, p record.UserCreateParams) ! {
	record.user_create(mut tx, p) or {
		return new_error_internal('Failed to create user', err.msg())
	}
}

// TODO update image
pub fn user_update(mut tx firebird.Transaction, user_id record.ID, p record.UserUpdateParams) ! {
	record.user_update(mut tx, user_id, p) or {
		return new_error_internal('Failed to create user', err.msg())
	}
}

pub fn user_delete(mut tx firebird.Transaction, user_id record.ID) ! {
	record.user_delete(mut tx, user_id) or {
		return new_error_internal('Failed to delete user', err.msg())
	}
}

pub type UserListParams = record.UserListParams

pub fn user_list_count(mut tx firebird.Transaction, p record.UserListParams) !i64 {
	count := record.user_list_count(mut tx, p) or {
		return new_error_internal('Failed to retrieve user count', err.msg())
	}
	return count
}

pub fn user_list(mut tx firebird.Transaction, p record.UserListParams) ![]record.User {
	users := record.user_list(mut tx, p) or {
		return new_error_internal('Failed to retrieve users', err.msg())
	}
	return users
}

pub fn user_get_by_id(mut tx firebird.Transaction, user_id record.ID) !record.User {
	users := record.user_list(mut tx, record.UserListParams{
		ids:    [user_id]
		offset: offset_default
		fetch:  1
		order:  order_default
	}) or { return new_error_internal('Failed to retrieve users', err.msg()) }

	if users.len == 0 {
		return new_error_not_found('user not found', 'No user exists with id `${user_id.string()}`')
	}

	return users[0]
}

pub fn user_get_by_email(mut tx firebird.Transaction, email string) !record.User {
	users := record.user_list(mut tx, record.UserListParams{
		email:  email
		offset: offset_default
		fetch:  1
		order:  order_default
	}) or { return new_error_internal('Failed to retrieve users', err.msg()) }

	if users.len == 0 {
		return new_error_not_found('user not found', 'No user exists with email `${email}`')
	}

	return users[0]
}

