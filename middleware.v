module main

import os
import net.http
import json

fn (mut app App) load_user_session_middleware(mut ctx Context) bool {
	session_name := '${os.getenv(env_session_admin_prefix)}-${os.getenv(env_session_name)}'
	ctx.user_session = app.session_store.new(ctx.req, session_name)

	// [/admin/auth; post] must accept unauthorized request to allow logins
	if ctx.req.url == '/admin/auth' && ctx.req.method == http.Method.post {
		return true
	}

	if ctx.user_session.is_new {
		ctx.text('Unauthorized')
		return false
	}

	ctx.user_session_values = json.decode(UserSessionValues, ctx.user_session.values) or {
		ctx.res.set_status(http.Status.internal_server_error)
		ctx.json(new_peony_error('Could not decode UserSessionValues', err.msg()))
		return false
	}

	return true
}

fn (mut app App) save_user_session_middleware(mut ctx Context) bool {
	ctx.user_session.values = json.encode(ctx.user_session_values)

	app.session_store.save(mut ctx.res.header, mut ctx.user_session) or {
		ctx.res.set_status(http.Status.internal_server_error)
		ctx.json(new_peony_error('failed to save session', err.msg()))
		return false
	}

	return true
}
