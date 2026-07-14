module peony

import json
import veb
import einar_hjortdal.firebird
import internal.common
import internal.conduit
import internal.errors
import objects

// lists users
@['/admin/users'; get]
pub fn (mut app App) admin_user_list(mut ctx Context) veb.Result {
	p := hygienise_user_list_request_query(ctx.query) or { return ctx.handle_error(err) }

	data := app.with_rollback(fn [p] (mut tx firebird.ClientTransaction) !conduit.List[conduit.User] {
		return conduit.user_list(mut tx, p)
	}) or { return ctx.handle_error(err) }

	return ctx.handle_ok(UserResponseListEnvelope{
		users:  format_user_response_list(data.items)
		count:  data.count
		offset: p.offset
		fetch:  p.fetch
	})
}

// creates a user
@['/admin/users'; post]
pub fn (mut app App) admin_users_post(mut ctx Context) veb.Result {
	p := json.decode(UserCreateRequest, ctx.req.data) or {
		return ctx.handle_error(errors.bad_request('Could not decode UserCreateRequest', err.msg()))
	}

	p.hygienise() or { return ctx.handle_error(err) }

	user_id := app.gen_id()
	password_hash := hash_password(p.password) or {
		return ctx.handle_error(errors.internal('Failed hash password', err.msg()))
	}
	password_parameters_encoded, password_parameters_hash := password_hash.parameters.encode() or {
		return ctx.handle_error(errors.internal('Failed to encode password_parameters', err.msg()))
	}

	user := app.with_commit(fn [mut app, p, user_id, password_hash, password_parameters_encoded, password_parameters_hash] (mut tx firebird.ClientTransaction) !conduit.User {
		password_details := conduit.password_details_get(mut tx, conduit.PasswordDetailsGetParams{
			hash: password_parameters_hash
		}) or {
			password_parameters_id := app.gen_id()
			conduit.password_details_create(mut tx, password_parameters_id, argon2id_name,
				password_parameters_encoded, password_parameters_hash)!
			conduit.password_details_get(mut tx, conduit.PasswordDetailsGetParams{
				hash: password_parameters_hash
			})!
		}

		if _ := p.image {
			// TODO
		}

		conduit.user_create(mut tx, conduit.UserCreateParams{
			user_id:                user_id
			handle:                 user_id.string() // TODO validate and format
			email:                  p.email
			password_hash:          password_hash.hash
			password_salt:          password_hash.salt
			password_parameters_id: password_details.id
			role:                   unwrap_option_or(p.role, objects.role_admin)
			first_name:             p.first_name
			last_name:              p.last_name
			// image_id
			metadata: p.metadata
		})!

		return conduit.user_get_by_id(mut tx, user_id)
	}) or { return ctx.handle_error(err) }

	return ctx.handle_created(UserResponseEnvelope{
		user: format_user_response(user)
	})
}

// requests a password reset
// sends a password reset email using the email provider
// ['/admin/users/password-token'; post]
// body: {email: string}

// reset password
// ['/admin/users/reset_password'; post]
// body: {
// token: string
// password: string
// }

// retrieves a user details
@['/admin/users/:user_id'; get]
pub fn (mut app App) get_user_by_id(mut ctx Context, user_id string) veb.Result {
	parsed_user_id := common.id_from_string(user_id) or {
		return ctx.handle_error(errors.unprocessable_entity(errors.id_invalid, 'user_id'))
	}

	user := app.with_rollback(fn [parsed_user_id] (mut tx firebird.ClientTransaction) !conduit.User {
		return conduit.user_get_by_id(mut tx, parsed_user_id)
	}) or { return ctx.handle_error(err) }

	return ctx.handle_ok(UserResponseEnvelope{
		user: format_user_response(user)
	})
}

// updates a user
@['/admin/users/:user_id'; post]
pub fn (mut app App) admin_users_id_post(mut ctx Context, user_id string) veb.Result {
	parsed_user_id := common.id_from_string(user_id) or {
		return ctx.handle_error(errors.bad_request(errors.id_invalid, 'user_id'))
	}

	p := json.decode(UserUpdateRequest, ctx.req.data) or {
		perr := errors.bad_request('Could not decode UserUpdateRequest', err.msg())
		return ctx.handle_error(perr)
	}

	p.hygienise() or { return ctx.handle_error(err) }

	user := app.with_commit(fn [parsed_user_id, p] (mut tx firebird.ClientTransaction) !conduit.User {
		conduit.user_update(mut tx, parsed_user_id, conduit.UserUpdateParams{
			email:      p.email
			first_name: p.first_name
			last_name:  p.last_name
			role:       p.role
			metadata:   p.metadata
		})!

		if _ := p.image {
			// TODO
		}

		return conduit.user_get_by_id(mut tx, parsed_user_id)
	}) or { return ctx.handle_error(err) }

	return ctx.handle_ok(UserResponseEnvelope{
		user: format_user_response(user)
	})
}

// deletes a user
@['/admin/users/:user_id'; delete]
pub fn (mut app App) admin_users_id_delete(mut ctx Context, user_id string) veb.Result {
	parsed_user_id := common.id_from_string(user_id) or {
		return ctx.handle_error(errors.bad_request(errors.id_invalid, 'user_id'))
	}

	app.with_commit(fn [parsed_user_id] (mut tx firebird.ClientTransaction) !common.Empty {
		conduit.user_delete(mut tx, parsed_user_id)!
		return common.Empty{}
	}) or { return ctx.handle_error(err) }

	return ctx.handle_deleted()
}
