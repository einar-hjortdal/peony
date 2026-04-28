module peony

import net.http
import json
import log
import conduit

pub const header_store_api_key = 'Peony-Store-API-Key'

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
		ctx.json(new_error_unauthorized('Invalid session', err.msg()))
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
	api_key_string := ctx.get_custom_header(header_store_api_key) or {
		ctx.res.set_status(http.Status.unauthorized)
		ctx.json(new_error_unauthorized(error_api_key_invalid,
			'Missing ${header_store_api_key} header'))
		return false
	}

	if api_key_string == '' {
		ctx.res.set_status(http.Status.unauthorized)
		ctx.json(new_error_unauthorized(error_api_key_invalid,
			'Empty ${header_store_api_key} header'))
		return false
	}

	api_key_id := id_from_string(api_key_string) or {
		ctx.res.set_status(http.Status.unprocessable_entity)
		ctx.json(new_error_unprocessable_entity(error_api_key_invalid, 'Could not parse API Key'))
		return false
	}

	if api_key := app.cache_get_api_key(api_key_id) {
		ctx.api_key = api_key
		return true
	}

	mut tx := app.start_transaction() or { return ctx.middleware_handle_error(err) }
	api_key := conduit.api_key_get(mut tx, api_key_id) or {
		tx.rollback() or {}
		return ctx.middleware_handle_error(err)
	}
	tx.rollback() or {}
	app.cache_set_api_key(api_key) or {} // TODO handle error
	ctx.api_key = api_key
	return true
}

