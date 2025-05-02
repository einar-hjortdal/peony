module main

import os
import net.http

fn (mut app App) session_middleware(mut ctx Context) bool {
	// [/admin/auth; post] must accept unauthorized request to log in
	if ctx.req.url == '/admin/auth' && ctx.req.method == http.Method.post {
		return true
	}

	ctx.session = app.session_store.new(ctx.req, os.getenv('SESSION_NAME'))
	if ctx.session.is_new {
		ctx.text('Unauthorized')
		return false
	}

	return true
}
