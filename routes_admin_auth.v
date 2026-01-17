module peony

import json
import veb

// returns details about the user that performed the request
@['/admin/auth'; get]
pub fn (mut app App) admin_auth_get(mut ctx Context) veb.Result {
	return conduit_user_get_by_id(mut app, mut ctx, ctx.user_session_values.id_bin)
}

// logs in user
@['/admin/auth'; post]
pub fn (mut app App) admin_auth_post(mut ctx Context) veb.Result {
	p := json.decode(AuthRequest, ctx.req.data) or {
		return handle_error_400(mut ctx, 'Could not decode AuthRequest', err.msg())
	}

	// return error 400 if bad email
	if p.email == '' {
		return handle_error_400(mut ctx, error_empty_field, 'email')
	}

	if p.password == '' {
		return handle_error_400(mut ctx, error_empty_field, 'password')
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
