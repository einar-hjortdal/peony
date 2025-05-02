module main

import json
import time
import veb

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
	created_at time.Time
	updated_at time.Time
	deleted_at time.Time @[omitempty]
	first_name string    @[omitempty]
	last_name  string    @[omitempty]
}

fn parse_user_response(u User) UserResponse {
	return UserResponse{
		id:         u.id
		handle:     u.handle
		email:      u.email
		role:       u.role
		created_at: u.created_at.Time
		updated_at: u.updated_at.Time
		deleted_at: u.deleted_at.value.Time
		first_name: u.first_name.value
		last_name:  u.last_name.value
	}
}

// creates a user
@['/admin/users/'; post]
fn (mut app App) admin_users_post(mut ctx Context) veb.Result {
	expected := json.decode(NewUserData, ctx.req.data) or {
		pe := new_peony_error(1, 'bad request')
		return ctx.json(pe)
	}

	// error if email obviously wrong?
	uid := app.create_user(expected) or {
		return ctx.json(new_peony_error(1, 'Failed to create user'))
	}
	u := app.retreieve_user(uid) or {
		return ctx.json(new_peony_error(1, 'Failed to retrieve the new user'))
	}
	return ctx.json(parse_user_response(u))
}
