module peony

import net.http
import json
import log
import einar_hjortdal.firebird
import internal.conduit
import internal.errors
import internal.common

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

		return ctx.middleware_handle_error(errors.unauthorized('Invalid session', err.msg()))
	}

	return true
}

fn (mut app App) middleware_save_user_session(mut ctx Context) bool {
	ctx.user_session.values = json.encode(ctx.user_session_values)

	app.session_store.save(mut ctx.res.header, ctx.user_session) or {
		return ctx.middleware_handle_error(errors.internal('Failed to save session', err.msg()))
	}

	return true
}

fn (mut app App) middleware_get_api_key(mut ctx Context) bool {
	api_key_string := ctx.get_custom_header(header_store_api_key) or {
		return ctx.middleware_handle_error(errors.unauthorized(error_api_key_invalid,
			'Missing ${header_store_api_key} header'))
	}

	if api_key_string == '' {
		return ctx.middleware_handle_error(errors.unauthorized(error_api_key_invalid,
			'Empty ${header_store_api_key} header'))
	}

	api_key_id := common.id_from_string(api_key_string) or {
		return ctx.middleware_handle_error((errors.unprocessable_entity(errors.id_invalid,
			'api_key')))
	}

	if api_key := app.cache_api_key_get(api_key_id) {
		ctx.api_key = api_key
		return true
	}

	api_key := app.with_rollback(fn [api_key_id] (mut tx firebird.ClientTransaction) !conduit.APIKey {
		return conduit.api_key_get(mut tx, api_key_id)
	}) or { return ctx.middleware_handle_error(err) }

	app.cache_api_key_set(api_key) or { log.error('failed to set APIKey in cache') }
	ctx.api_key = api_key
	return true
}
