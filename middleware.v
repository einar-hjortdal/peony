module peony

import net.http
import json
import log

pub const header_api_key = 'Peony-API-Key'

fn (mut app App) middleware_debug(mut ctx Context) bool {
	log.debug('Received request: ${ctx.req.url} ${ctx.req.method}')
	return true
}

fn (mut app App) middleware_load_user_session(mut ctx Context) bool {
	session_name := '${app.config.session_admin_prefix}-${app.config.session_name}'
	ctx.user_session = app.session_store.new(ctx.req, session_name)

	ctx.user_session_values = json.decode(UserSessionValues, ctx.user_session.values) or {
		// [/admin/auth; post] must accept unauthorized request to allow logins
		if ctx.req.url == '/admin/auth' && ctx.req.method == http.Method.post {
			return true
		}

		ctx.res.set_status(http.Status.unauthorized)
		ctx.json(new_error_internal('Invalid session', err.msg()))
		return false
	}

	return true
}

fn (mut app App) middleware_save_user_session(mut ctx Context) bool {
	ctx.user_session.values = json.encode(ctx.user_session_values)

	app.session_store.save(mut ctx.res.header, ctx.user_session) or {
		ctx.res.set_status(http.Status.internal_server_error)
		ctx.json(new_error_internal('Failed to save session', err.msg()))
		return false
	}

	return true
}

fn (mut app App) middleware_get_api_key(mut ctx Context) bool {
	api_key_string := ctx.get_custom_header(header_api_key) or { return true }
	if api_key_string == '' {
		return true
	}

	api_key := id_from_string(api_key_string) or {
		ctx.res.set_status(http.Status.bad_request)
		ctx.json(new_error_bad_request('Invalid API key', err.msg()))
		return false
	}

	// TODO set api key in context

	return true
}

