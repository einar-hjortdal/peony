module peony

import json
import log
import veb

// returns details about the user that performed the request
@['/admin/auth'; get]
pub fn (mut app App) admin_auth_get(mut ctx Context) veb.Result {
	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	user := conduit_user_get_by_id(mut app, mut tx, ctx.user_session_values.id) or {
		tx.rollback() or {}
		return ctx.handle_error(err)
	}

	tx.rollback() or {
		perr := new_error_internal(error_transaction_rollback, err.msg())
		return ctx.handle_error(perr)
	}

	return ctx.handle_ok(UserResponseEnvelope{
		user: format_user_response(user)
	})
}

// logs in user
@['/admin/auth'; post]
pub fn (mut app App) user_login(mut ctx Context) veb.Result {
	if !ctx.user_session_values.id.is_null() {
		perr := new_error_bad_request('Already logged in', 'user session exists')
		return ctx.handle_error(perr)
	}

	p := json.decode(AuthRequest, ctx.req.data) or {
		perr := new_error_bad_request('Could not decode AuthRequest', err.msg())
		return ctx.handle_error(perr)
	}

	if p.email == '' {
		perr := new_error_bad_request(error_field_empty, 'email')
		return ctx.handle_error(perr)
	}

	if p.password == '' {
		perr := new_error_bad_request(error_field_empty, 'password')
		return ctx.handle_error(perr)
	}

	email_is_valid(p.email) or {
		perr := new_error_bad_request('Invalid email', err.msg())
		return ctx.handle_error(perr)
	}
	// TODO quick validate email: min/max char length, shape and presence of @ and .
	// return error if user already logged in

	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	user := conduit_user_get_by_email(mut app, mut tx, p.email) or {
		tx.rollback() or {}
		return ctx.handle_error(err)
	}

	tx.rollback() or {
		perr := new_error_internal(error_transaction_rollback, err.msg())
		return ctx.handle_error(perr)
	}

	verify_password(p.password, user.password_hash, user.password_salt) or {
		log.debug(err.msg())
		perr := new_error_login()
		return ctx.handle_error(perr)
	}

	ctx.user_session_values = UserSessionValues{
		id: user.id
	}

	return ctx.handle_ok(UserResponseEnvelope{
		user: format_user_response(user)
	})
}

// logs out user
@['/admin/auth'; delete]
pub fn (mut app App) admin_auth_del(mut ctx Context) veb.Result {
	ctx.user_session.to_prune = true
	return success(mut ctx)
}

