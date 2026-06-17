module conduit

import einar_hjortdal.firebird
import record
import internal.common
import internal.errors

// TODO create image
pub fn user_create(mut tx firebird.ClientTransaction, p UserCreateParams) ! {
	record.user_create(mut tx, p) or { return errors.internal('Failed to create user', err.msg()) }
}

// TODO update image
pub fn user_update(mut tx firebird.ClientTransaction, user_id ID, p record.UserUpdateParams) ! {
	record.user_update(mut tx, user_id, p) or {
		return errors.internal('Failed to create user', err.msg())
	}
}

pub fn user_delete(mut tx firebird.ClientTransaction, user_id ID) ! {
	record.user_delete(mut tx, user_id) or {
		return errors.internal('Failed to delete user', err.msg())
	}
}

pub fn user_list_count(mut tx firebird.ClientTransaction, p UserListParams) !i64 {
	count := record.user_list_count(mut tx, p) or {
		return errors.internal('Failed to retrieve user count', err.msg())
	}
	return count
}

pub fn user_list(mut tx firebird.ClientTransaction, p UserListParams) ![]User {
	users := record.user_list(mut tx, p) or {
		return errors.internal('Failed to retrieve users', err.msg())
	}
	return users
}

pub fn user_get_by_id(mut tx firebird.ClientTransaction, user_id ID) !User {
	users := record.user_list(mut tx, record.UserListParams{
		ids:    [user_id]
		offset: offset_default
		fetch:  1
		order:  order_default
	}) or { return errors.internal('Failed to retrieve users', err.msg()) }

	if users.len == 0 {
		return errors.not_found('user not found', 'No user exists with id `${user_id.string()}`')
	}

	return users[0]
}

pub fn user_get_by_email(mut tx firebird.ClientTransaction, email string) !User {
	users := record.user_list(mut tx, record.UserListParams{
		email:  email
		offset: offset_default
		fetch:  1
		order:  order_default
	}) or { return errors.internal('Failed to retrieve users', err.msg()) }

	if users.len == 0 {
		return errors.not_found('user not found', 'No user exists with email `${email}`')
	}

	return users[0]
}


