module peony

import json
import veb

// retrieves a list of users
@['/admin/users/'; get]
pub fn (mut app App) admin_users_get(mut ctx Context) veb.Result {
	return ctx.text('ok')
}

// creates a user
@['/admin/users/'; post]
pub fn (mut app App) admin_users_post(mut ctx Context) veb.Result {
	body := json.decode(NewUserData, ctx.req.data) or {
		return handle_error_400(mut ctx, 'Could not decode NewUserData', err.msg())
	}

	// TODO validate email
	// error if email obviously wrong?
	id, id_bin := app.new_id()

	// TODO move to conduit function
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	model_user_create(mut tx, body, id, id_bin) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Failed to create user', err.msg())
	}

	tx.commit() or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, error_transaction_commit, err.msg())
	}

	return success(mut ctx)
}

// requests a password reset
// ['/admin/users/password-token'; post]
// body: {email: string}

// reset password
// ['/admin/users/reset_password'; post]
// body: {
// token: string
// password: string
// }

// retrieves a user details
@['/admin/users/:id'; get]
pub fn (mut app App) admin_users_id_get(mut ctx Context, id string) veb.Result {
	id_bin := id_string_to_bin(id) or {
		return handle_error_400(mut ctx, error_id_invalid, err.msg())
	}

	user := app.retrieve_user_by_id(id_bin) or {
		return handle_error_500(mut ctx, 'Could not retrieve user from database', err.msg())
	}
	return ctx.json(format_user_response(user))
}

// updates a user
@['/admin/users/:id'; post]
pub fn (mut app App) admin_users_id_post(mut ctx Context, id string) veb.Result {
	id_bin := id_string_to_bin(id) or {
		return handle_error_400(mut ctx, 'Malformed id', err.msg())
	}

	body := json.decode(UpdateUserData, ctx.req.data) or {
		return handle_error_400(mut ctx, 'Could not decode UpdateUserData', err.msg())
	}

	// TODO move to conduit function
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	model_user_update(mut tx, id_bin, body) or {
		return handle_error_500(mut ctx, 'Failed to update user', err.msg())
	}

	tx.commit() or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, error_transaction_commit, err.msg())
	}

	updated_user := app.retrieve_user_by_id(id_bin) or {
		return handle_error_500(mut ctx, 'Failed to retrieve the updated user', err.msg())
	}

	return ctx.json(format_user_response(updated_user))
}

// deletes a user
@['/admin/users/:id'; post]
pub fn (mut app App) admin_users_id_delete(mut ctx Context, id string) veb.Result {
	id_bin := id_string_to_bin(id) or {
		return handle_error_400(mut ctx, 'Malformed id', err.msg())
	}

	// TODO move to conduit function
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	model_user_delete(mut tx, id_bin) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Failed to delete user', err.msg())
	}

	tx.commit() or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, error_transaction_commit, err.msg())
	}

	return success(mut ctx)
	// {
	// 	id:      id
	// 	deleted: true
	// 	deleted: true
	// }
}
