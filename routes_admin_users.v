module main

import json
import net.http
import veb

// retrieves a list of users
@['/admin/users/'; get]
fn (app &App) admin_users_get(mut ctx Context) veb.Result {
	return ctx.text('ok')
}

// creates a user
@['/admin/users/'; post]
fn (mut app App) admin_users_post(mut ctx Context) veb.Result {
	body := json.decode(NewUserData, ctx.req.data) or {
		ctx.res.set_status(http.Status.bad_request)
		return ctx.json(new_peony_error('Could not decode NewUserData', err.msg()))
	}

	// error if email obviously wrong?
	_, id_bin := app.create_user(body) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Failed to create user', err.msg()))
	}
	u := app.retrieve_user_by_id(id_bin) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Failed to retrieve the new user', err.msg()))
	}
	return ctx.json(format_user_response(u))
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
fn (mut app App) admin_users_id_get(mut ctx Context, id string) veb.Result {
	id_bin := id_string_to_bin(id) or {
		ctx.res.set_status(http.Status.bad_request)
		return ctx.json(new_peony_error('Malformed id', err.msg()))
	}

	user := app.retrieve_user_by_id(id_bin) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Could not retrieve user from database', err.msg()))
	}
	return ctx.json(format_user_response(user))
}

// updates a user
@['/admin/users/:id'; post]
fn (mut app App) admin_users_id_post(mut ctx Context, id string) veb.Result {
	id_bin := id_string_to_bin(id) or {
		ctx.res.set_status(http.Status.bad_request)
		return ctx.json(new_peony_error('Malformed id', err.msg()))
	}

	body := json.decode(UpdateUserData, ctx.req.data) or {
		ctx.res.set_status(http.Status.bad_request)
		return ctx.json(new_peony_error('Could not decode UpdateUserData', err.msg()))
	}

	app.update_user(id_bin, body) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Failed to update user', err.msg()))
	}

	updated_user := app.retrieve_user_by_id(id_bin) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Failed to retrieve the updated user', err.msg()))
	}

	return ctx.json(format_user_response(updated_user))
}

// deletes a user
@['/admin/users/:id'; post]
fn (mut app App) admin_users_id_delete(mut ctx Context, id string) veb.Result {
	id_bin := id_string_to_bin(id) or {
		ctx.res.set_status(http.Status.bad_request)
		return ctx.json(new_peony_error('Malformed id', err.msg()))
	}

	app.delete_user(id_bin) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Failed to delete user', err.msg()))
	}
	return ctx.text('ok')
	// {
	// 	id:      id
	// 	deleted: true
	// 	deleted: true
	// }
}
