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

	password := p.password.trim_space()
	if password == '' {
		return ctx.handle_error(errors.bad_request(error_field_empty, 'password'))
	}

	email := normalize_email(p.email)
	common.email_is_valid(email) or {
		return ctx.handle_error(errors.bad_request('Invalid email', err.msg()))
	}

	data := app.with_rollback(fn [email] (mut tx firebird.ClientTransaction) !LoginData {
		user := conduit.user_get_by_email(mut tx, email)!
		password_details := conduit.password_details_get(mut tx, conduit.PasswordDetailsGetParams{
			id: user.password_details_id
		})!

		return LoginData{
			user:             user
			password_details: password_details
		}
	}) or { return ctx.handle_error(err) }

	verify_password(password, data.user.password_hash, data.user.password_salt,
		data.password_details.function_name, data.password_details.parameters) or {
		return ctx.handle_error(err)
	}

	ctx.user_session_values = UserSessionValues{
		id: data.user.id
	}

	return ctx.handle_ok(UserResponseEnvelope{
		user: format_user_response(data.user)
	})
}

// logs out user
@['/admin/auth'; delete]
pub fn (mut app App) admin_auth_del(mut ctx Context) veb.Result {
	ctx.user_session.to_prune = true
	return ctx.handle_deleted()
}

// Creates a password reset token for a user.
// Prevent email enumeration by returning HTTP status 201 Created even if no user exist with the given email.
@['/admin/auth/password_reset'; post]
pub fn (mut app App) user_password_reset_token_create(mut ctx Context) veb.Result {
	request := json2.decode[PasswordResetTokenCreateRequest](ctx.req.data) or {
		return ctx.handle_error(errors.bad_request('Could not decode PasswordResetTokenCreateRequest',
			err.msg()))
	}

	email := normalize_email(request.email)
	common.email_is_valid(email) or {
		return ctx.handle_error(errors.bad_request('invalid email', err.msg()))
	}

	data := app.with_commit(fn [mut app, email] (mut tx firebird.ClientTransaction) !string {
		user := conduit.user_get_by_email(mut tx, email)!

		token_id := common.new_id(mut app.luuid_generator)
		token := new_password_reset_token() or {
			return errors.internal('Failed to generate token', err.msg())
		}

		password_hash := hash_password(token) or {
			return errors.internal('Failed to hash password', err.msg())
		}

		password_parameters_encoded, password_parameters_hash := password_hash.encode_parameters() or {
			return errors.internal('Failed to encode password_parameters', err.msg())
		}

		// TODO would be better to put this logic in a new conduit function, it will be used 3 times, maybe more.
		password_details := conduit.password_details_get(mut tx, conduit.PasswordDetailsGetParams{
			hash: password_parameters_hash
		}) or {
			password_parameters_id := app.gen_id()
			conduit.password_details_create(mut tx, password_parameters_id,
				password_hash.function_name(), password_parameters_encoded,
				password_parameters_hash)!
			conduit.password_details_get(mut tx, conduit.PasswordDetailsGetParams{
				hash: password_parameters_hash
			})!
		}

		// TODO get password_reset_token if any valid and delete, else create.
		// conduit.password_reset_token_admin_get(mut tx, user_id)!
		// if exists delete, then continue

		conduit.password_reset_token_create(mut tx, conduit.PasswordResetTokenCreateParams{
			id:                  token_id
			user_id:             user.id
			password_hash:       password_hash.hash
			password_salt:       password_hash.salt
			password_details_id: password_details.id
		})!

		// trigger event that may send notification, token should be accessible by callback.
		// notification record has to be created in db if a callback is defined
		return token
	}) or {
		if err.code() == 404 {
			return ctx.handle_password_reset()
		}
		return ctx.handle_error(err)
	}

	// for now, use 2 transactions. When worker mode is ready, delegate rest of work to worker.
	// at completion update notification status to success/failure
	return ctx.handle_password_reset()
}

// Resets a password using a password reset token
@['/admin/auth/password_reset/:password_reset_token'; post]
pub fn (mut app App) user_password_reset_token_consume(mut ctx Context, password_reset_token string) veb.Result {
	request := json2.decode[PasswordResetTokenConsumeRequest](ctx.req.data) or {
		return ctx.handle_error(errors.bad_request('Could not decode PasswordResetTokenConsumeRequest',
			err.msg()))
	}

	password := request.password.trim_space()
	if password == '' {
		return ctx.handle_error(errors.bad_request(error_field_empty, 'password'))
	}

	decoded := decode_password_reset_token(password_reset_token)

	user := app.with_commit(fn [app, request] (mut tx firebird.ClientTransaction) !conduit.User {
		// check token is valid:
		// 1. password_reset_token row exist and is not expired/deleted
		// 2. get password_details using password_details_id
		// 3. validate token hash using password_details, hash and salt
		// 4. update password on user
		// 5. retrieve user
	}) or { return ctx.handle_error(err) }

	return ctx.handle_ok(UserResponseEnvelope{
		user: format_user_response(data.user)
	})
}
