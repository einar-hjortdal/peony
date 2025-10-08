module peony

import json
import veb

// retrieves a list of users
@['/admin/users/'; get]
pub fn (mut app App) admin_users_get(mut ctx Context) veb.Result {
	return ctx.json('TODO')
}

// creates a user
@['/admin/users/'; post]
pub fn (mut app App) admin_users_post(mut ctx Context) veb.Result {
	p := json.decode(UserCreateRequest, ctx.req.data) or {
		return handle_error_400(mut ctx, 'Could not decode UserCreateRequest', err.msg())
	}

	// TODO validate email, error if email obviously bad

	return conduit_user_create(mut app, mut ctx, p)
}

// requests a password reset
// sends a password reset email using the email provider
// ['/admin/users/password-token'; post]
// body: {email: string}

// reset password
// ['/admin/users/reset_password'; post]
// body: {
// token: string
// password: string
// }

// retrieves a user details
@['/admin/users/:user_id'; get]
pub fn (mut app App) admin_users_id_get(mut ctx Context, user_id string) veb.Result {
	user_id_bin := id_string_to_bin(user_id) or {
		return handle_error_400(mut ctx, error_id_invalid, 'user_id')
	}

	user := app.retrieve_user_by_id(user_id_bin) or {
		return handle_error_500(mut ctx, 'Could not retrieve user from database', err.msg())
	}
	return ctx.json(format_user_response(user))
}

// updates a user
@['/admin/users/:user_id'; post]
pub fn (mut app App) admin_users_id_post(mut ctx Context, user_id string) veb.Result {
	user_id_bin := id_string_to_bin(user_id) or {
		return handle_error_400(mut ctx, error_id_invalid, 'user_id')
	}

	p := json.decode(UserUpdateRequest, ctx.req.data) or {
		return handle_error_400(mut ctx, 'Could not decode UserUpdateRequest', err.msg())
	}

	return conduit_user_update(mut app, mut ctx, user_id_bin, p)
}

// deletes a user
@['/admin/users/:user_id'; post]
pub fn (mut app App) admin_users_id_delete(mut ctx Context, user_id string) veb.Result {
	user_id_bin := id_string_to_bin(user_id) or {
		return handle_error_400(mut ctx, error_id_invalid, 'user_id')
	}

	// TODO move to conduit function
	return conduit_user_delete(mut app, mut ctx, user_id_bin)
}
