module main

import os
import net.http

// TODO
// SESSION_REFRESH_EXPIRE

fn (mut app App) load_session_middleware(mut ctx Context) bool {
	// [/admin/auth; post] must accept unauthorized request to log in
	if ctx.req.url == '/admin/auth' && ctx.req.method == http.Method.post {
		return true
	}

	ctx.session = app.session_store.new(ctx.req, os.getenv(env_session_name))
	// check if prefix with env_session_admin_prefix
	if ctx.session.is_new {
		ctx.text('Unauthorized')
		return false
	}

	return true
}

fn (mut app App) save_session_middleware(mut ctx Context) bool {
	app.session_store.save(mut ctx.res.header, mut ctx.session) or {
		ctx.json(new_peony_error(0, 'failed to save session'))
		return false
	}
	return true
}
