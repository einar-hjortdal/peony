module main

import os
import net.http
import json
import log

fn (mut app App) middleware_debug(mut ctx Context) bool {
	log.debug('Received request: ${ctx.req.url} ${ctx.req.method}')
	return true
}

fn (mut app App) middleware_load_user_session(mut ctx Context) bool {
	session_name := '${os.getenv(env_session_admin_prefix)}-${os.getenv(env_session_name)}'
	ctx.user_session = app.session_store.new(ctx.req, session_name)

	// [/admin/auth; post] must accept unauthorized request to allow logins
	if ctx.req.url == '/admin/auth' && ctx.req.method == http.Method.post {
		return true
	}

	ctx.user_session_values = json.decode(UserSessionValues, ctx.user_session.values) or {
		ctx.res.set_status(http.Status.internal_server_error)
		ctx.json(new_peony_error('Could not decode UserSessionValues', err.msg()))
		return false
	}

	return true
}

fn (mut app App) middleware_save_user_session(mut ctx Context) bool {
	ctx.user_session.values = json.encode(ctx.user_session_values)

	app.session_store.save(mut ctx.res.header, mut ctx.user_session) or {
		ctx.res.set_status(http.Status.internal_server_error)
		ctx.json(new_peony_error('Failed to save session', err.msg()))
		return false
	}

	return true
}
