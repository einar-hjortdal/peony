module peony

import json
import veb

// returns details about the user that performed the request
@['/admin/auth'; get]
pub fn (mut app App) admin_auth_get(mut ctx Context) veb.Result {
	return conduit_user_get_by_id(mut app, mut ctx, ctx.user_session_values.id)
}

// logs in user
@['/admin/auth'; post]
pub fn (mut app App) admin_auth_post(mut ctx Context) veb.Result {
	if !ctx.user_session_values.id.is_null() {
		perr := new_error_bad_request('Already logged in', 'user session exists')
		return ctx.handle_error(perr)
	}

	p := json.decode(AuthRequest, ctx.req.data) or {
		perr := new_error_bad_request('Could not decode AuthRequest', err.msg())
		return ctx.handle_error(perr)
	}

	if p.email == '' {
		perr := new_error_bad_request(error_field_empty, 'email')
		return ctx.handle_error(perr)
	}

	if p.password == '' {
		perr := new_error_bad_request(error_field_empty, 'password')
		return ctx.handle_error(perr)
	}

	email_is_valid(p.email) or {
		perr := new_error_bad_request('Invalid email', err.msg())
		return ctx.handle_error(perr)
	}
	// TODO quick validate email: min/max char length, shape and presence of @ and .
	// return error if user already logged in

	return conduit_auth_user(mut app, mut ctx, p)
}

// logs out user
@['/admin/auth'; delete]
pub fn (mut app App) admin_auth_del(mut ctx Context) veb.Result {
	ctx.user_session.to_prune = true
	return success(mut ctx)
}

