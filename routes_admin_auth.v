module peony

import json2
import veb
import einar_hjortdal.firebird
import internal.common
import internal.conduit
import internal.errors

// returns details about the user that performed the request
@['/admin/auth'; get]
pub fn (mut app App) admin_auth_get(mut ctx Context) veb.Result {
	user_id := ctx.user_session_values.id or {
		return ctx.handle_error(errors.internal('User is not authorized',
			'user session has no user id'))
	}

	user := app.with_rollback(fn [user_id] (mut tx firebird.ClientTransaction) !conduit.User {
		return conduit.user_get_by_id(mut tx, user_id)
	}) or { return ctx.handle_error(err) }

	return ctx.handle_ok(UserResponseEnvelope{
		user: format_user_response(user)
	})
}

struct LoginData {
	user             conduit.User
	password_details conduit.PasswordDetails
}

// logs in user
@['/admin/auth'; post]
pub fn (mut app App) user_login(mut ctx Context) veb.Result {
	if ctx.user_session_values.id != none {
		return ctx.handle_error(errors.bad_request('Already logged in', 'user session exists'))
	}

	p := json2.decode[AuthRequest](ctx.req.data) or {
		return ctx.handle_error(errors.bad_request('Could not decode AuthRequest', err.msg()))
	}

	if p.password == '' {
		return ctx.handle_error(errors.bad_request(error_field_empty, 'password'))
	}

	email := normalize_email(p.email)
	common.email_is_valid(email) or {
		return ctx.handle_error(errors.bad_request('Invalid email', err.msg()))
	}

	data := app.with_rollback(fn [email] (mut tx firebird.ClientTransaction) !LoginData {
		user := conduit.user_get_by_email(mut tx, email)!
		password_details := conduit.password_details_get(mut tx, conduit.PasswordDetailsGetParams{
			id: user.password_parameters_id
		})!

		return LoginData{
			user:             user
			password_details: password_details
		}
	}) or { return ctx.handle_error(err) }

	match data.password_details.function_name {
		argon2id_name {
			parameters := decode_argon2id_parameters(data.password_details.parameters) or {
				return ctx.handle_error(errors.login())
			}

			argon2id_hash := Argon2idHash{
				hash:       data.user.password_hash
				salt:       data.user.password_salt
				parameters: parameters
			}

			argon2id_hash.verify_password(p.password) or { return ctx.handle_error(errors.login()) }

			ctx.user_session_values = UserSessionValues{
				id: data.user.id
			}

			return ctx.handle_ok(UserResponseEnvelope{
				user: format_user_response(data.user)
			})
		}
		else {
			return ctx.handle_error(errors.internal('Unsupported password hashing algorithm',
				'decoded function name: `${data.password_details.function_name}`'))
		}
	}
}

// logs out user
@['/admin/auth'; delete]
pub fn (mut app App) admin_auth_del(mut ctx Context) veb.Result {
	ctx.user_session.to_prune = true
	return ctx.handle_deleted()
}
