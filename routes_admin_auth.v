module peony

import json
import veb

// returns details about the user that performed the request
@['/admin/auth/'; get]
pub fn (mut app App) admin_auth_get(mut ctx Context) veb.Result {
	user := app.retrieve_user_by_id(ctx.user_session_values.id_bin) or {
		return handle_error_500(mut ctx, 'Could not retrieve user data', err.msg())
	}
	return ctx.json(UserResponseEnvelope{
		user: format_user_response(user)
	})
}

// log in user
@['/admin/auth/'; post]
pub fn (mut app App) admin_auth_post(mut ctx Context) veb.Result {
	p := json.decode(AuthRequest, ctx.req.data) or {
		return handle_error_400(mut ctx, 'Could not decode AuthRequest', err.msg())
	}

	// TODO quick validate email: min/max char length, shape and presence of @ and .
	// return malformed request if bad

	return conduit_auth_user(mut app, mut ctx, p)
}

// log out user
@['/admin/auth/'; delete]
pub fn (app &App) admin_auth_del(mut ctx Context) veb.Result {
	ctx.user_session.to_prune = true
	return success(mut ctx)
}
