module main

import json
import net.http
import veb

// log in user
@['/admin/auth/'; post]
fn (mut app App) admin_auth_post(mut ctx Context) veb.Result {
	body := json.decode(struct {
		email    string
		password string
	}, ctx.req.data) or {
		ctx.res.set_status(http.Status.bad_request)
		return ctx.json(new_peony_error('bad request', err.msg()))
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
		id: user.id
	}

	return ctx.json(format_user_response(user))
}

// log out user
@['/admin/auth/'; del]
fn (app &App) admin_auth_del(mut ctx Context) veb.Result {
	ctx.user_session.to_prune = true
	return ctx.text('ok')
}
