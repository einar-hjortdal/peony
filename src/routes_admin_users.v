module main

import json
import veb
import einar_hjortdal.firebird

// retrieves a list of users
@['/admin/users/'; get]
fn (app &App) admin_users_get(mut ctx Context) veb.Result {
	return ctx.text('ok')
}

struct UserResponse {
	id         string
	handle     string
	email      string
	role       string
	created_at firebird.DateTime
	updated_at firebird.DateTime
	deleted_at firebird.DateTime @[omitempty]
	first_name string            @[omitempty]
	last_name  string            @[omitempty]
}

fn format_user_response(u User) UserResponse {
	return UserResponse{
		id:         u.id
		handle:     u.handle
		email:      u.email
		role:       u.role
		created_at: u.created_at
		updated_at: u.updated_at
		deleted_at: u.deleted_at
		first_name: u.first_name
		last_name:  u.last_name
	}
}

// creates a user
@['/admin/users/'; post]
fn (mut app App) admin_users_post(mut ctx Context) veb.Result {
	body := json.decode(NewUserData, ctx.req.data) or {
		return ctx.json(new_peony_error('Could not decode NewUserData', err.msg()))
	}

	// error if email obviously wrong?
	uid := app.create_user(body) or {
		return ctx.json(new_peony_error('Failed to create user', err.msg()))
	}
	u := app.retrieve_user_by_id(uid) or {
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
	user := app.retrieve_user_by_id(id) or {
		return ctx.json(new_peony_error('Could not retrieve user from database', err.msg()))
	}
	return ctx.json(format_user_response(user))
}

// updates a user
@['/admin/users/:id'; post]
fn (mut app App) admin_users_id_post(mut ctx Context, id string) veb.Result {
	body := json.decode(UpdateUserData, ctx.req.data) or {
		return ctx.json(new_peony_error('Could not decode UpdateUserData', err.msg()))
	}

	app.update_user(id, body) or {
		return ctx.json(new_peony_error('Failed to update user', err.msg()))
	}

	updated_user := app.retrieve_user_by_id(id) or {
		return ctx.json(new_peony_error('Failed to retrieve the updated user', err.msg()))
	}

	return ctx.json(format_user_response(updated_user))
}

// deleted a user
@['/admin/users/:id'; post]
fn (mut app App) admin_users_id_delete(mut ctx Context, id string) veb.Result {
	app.delete_user(id) or { return ctx.json(new_peony_error('Failed to delete user', err.msg())) }
	return ctx.text('ok')
	// {
	// 	id:      id
	// 	deleted: true
	// 	deleted: true
	// }
}
