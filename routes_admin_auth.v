module peony

import json
import veb
import conduit

// returns details about the user that performed the request
@['/admin/auth'; get]
pub fn (mut app App) admin_auth_get(mut ctx Context) veb.Result {
	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	user_id := ctx.user_session_values.id or {
		perr := new_error_internal('User is not authorized', 'user session has no user id')
		return ctx.handle_error(perr)
	}

	user := conduit.user_get_by_id(mut tx, user_id) or {
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
	if ctx.user_session_values.id != none {
		perr := new_error_bad_request('Already logged in', 'user session exists')
		return ctx.handle_error(perr)
	}

	p := json.decode(AuthRequest, ctx.req.data) or {
		perr := new_error_bad_request('Could not decode AuthRequest', err.msg())
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

	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	user := conduit.user_get_by_email(mut tx, p.email) or {
		tx.rollback() or {}
		return ctx.handle_error(err)
	}

	password_details := conduit.password_details_get(mut tx, conduit.PasswordDetailsGetParams{
		id: user.password_parameters_id
	}) or {
		tx.rollback() or {}
		return ctx.handle_error(err)
	}

	tx.rollback() or {
		perr := new_error_internal(error_transaction_rollback, err.msg())
		return ctx.handle_error(perr)
	}

	match password_details.function_name {
		argon2id_name {
			parameters := decode_argon2id_parameters(password_details.parameters) or {
				return ctx.handle_error(new_error_login())
			}

			argon2id_hash := Argon2idHash{
				hash:       user.password_hash
				salt:       user.password_salt
				parameters: parameters
			}

			argon2id_hash.verify_password(p.password) or {
				return ctx.handle_error(new_error_login())
			}

			ctx.user_session_values = UserSessionValues{
				id: user.id
			}

			return ctx.handle_ok(UserResponseEnvelope{
				user: format_user_response(user)
			})
		}
		else {
			perr := new_error_internal('Unsupported password hashing algorithm',
				'decoded function name: `${password_details.function_name}`')
			return ctx.handle_error(perr)
		}
	}
}

// logs out user
@['/admin/auth'; delete]
pub fn (mut app App) admin_auth_del(mut ctx Context) veb.Result {
	ctx.user_session.to_prune = true
	return ctx.handle_ok('logged out')
}

