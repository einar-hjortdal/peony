module main

import json
import net.http
import veb

// returns details about the user that performed the request
@['/admin/auth/'; get]
fn (mut app App) admin_auth_get(mut ctx Context) veb.Result {
	user := app.retrieve_user_by_id(ctx.user_session_values.id_bin) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Could not retrieve user data', err.msg()))
	}
	return ctx.json(format_user_response(user))
}

// log in user
@['/admin/auth/'; post]
fn (mut app App) admin_auth_post(mut ctx Context) veb.Result {
	body := json.decode(AuthRequest, ctx.req.data) or {
		ctx.res.set_status(http.Status.bad_request)
		return ctx.json(new_peony_error('Could not decode AuthRequest', err.msg()))
	}

	user := app.retrieve_user_by_email(body.email) or {
		ctx.res.set_status(http.Status.unauthorized)
		return ctx.json(new_peony_error('Invalid email or password', err.msg()))
	}

	verify_password(body.password, user.password_hash, user.password_salt) or {
		ctx.res.set_status(http.Status.unauthorized)
		return ctx.json(new_peony_error('Invalid email or password', err.msg()))
	}

	ctx.user_session_values = UserSessionValues{
		id:     user.id
		id_bin: user.id_bin
	}

	return ctx.json(format_user_response(user))
}

// log out user
@['/admin/auth/'; delete]
fn (app &App) admin_auth_del(mut ctx Context) veb.Result {
	ctx.user_session.to_prune = true
	return ctx.text('ok')
}
