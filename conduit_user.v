module peony

import log
import veb
import einar_hjortdal.firebird

fn conduit_user_create(mut app App, mut ctx Context, p UserCreateRequest) veb.Result {
	password_hash := hash_password(p.password) or {
		perr := new_error_internal('Failed hash password', err.msg())
		return ctx.handle_error(perr)
	}
	password_parameters_encoded, password_parameters_hash := password_hash.parameters.encode() or {
		perr := new_error_internal('Failed to encode password_parameters', err.msg())
		return ctx.handle_error(perr)
	}
	user_id := app.gen_id()

	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	password_details := model_password_details_get(mut tx, PasswordDetailsGetParams{
		hash: password_parameters_hash
	}) or {
		password_parameters_id := app.gen_id()
		model_password_details_create(mut tx, password_parameters_id, argon2id_name,
			password_parameters_encoded, password_parameters_hash) or {
			tx.rollback() or {}
			perr := new_error_internal('Failed to create password_parameters', err.msg())
			return ctx.handle_error(perr)
		}

		model_password_details_get(mut tx, PasswordDetailsGetParams{
			hash: password_parameters_hash
		}) or {
			tx.rollback() or {}
			perr := new_error_internal('Failed to get password_parameters', err.msg())
			return ctx.handle_error(perr)
		}
	}

	if image := p.image {
		println('TODO create image: ${image}')
	}

	model_user_create(mut tx, UserCreateParams{
		user_id:                user_id
		handle:                 user_id.string() // TODO validate and format in route
		email:                  p.email
		password_hash:          password_hash.hash
		password_salt:          password_hash.salt
		password_parameters_id: password_details.id
		role:                   unwrap_option_or(p.role, role_admin) // TODO validate and format in route
		first_name:             p.first_name
		last_name:              p.last_name
		// image_id
		metadata: p.metadata
	}) or {
		tx.rollback() or {}
		perr := new_error_internal('Failed to create user', err.msg())
		return ctx.handle_error(perr)
	}

	tx.commit() or {
		tx.rollback() or {}
		perr := new_error_internal(error_transaction_commit, err.msg())
		return ctx.handle_error(perr)
	}

	return success(mut ctx)
}

fn conduit_user_update(mut app App, mut ctx Context, user_id_bin []u8, p UserUpdateRequest) veb.Result {
	// TODO password
	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	if image := p.image {
		println('TODO update image: ${image}')
	}

	model_user_update(mut tx, user_id_bin, p) or {
		tx.rollback() or {}
		perr := new_error_internal('Failed to create user', err.msg())
		return ctx.handle_error(perr)
	}

	tx.commit() or {
		tx.rollback() or {}
		perr := new_error_internal(error_transaction_commit, err.msg())
		return ctx.handle_error(perr)
	}

	return success(mut ctx)
}

fn conduit_user_delete(mut app App, mut ctx Context, user_id_bin []u8) veb.Result {
	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	model_user_delete(mut tx, user_id_bin) or {
		tx.rollback() or {}
		perr := new_error_internal('Failed to delete user', err.msg())
		return ctx.handle_error(perr)
	}

	tx.commit() or {
		tx.rollback() or {}
		perr := new_error_internal(error_transaction_commit, err.msg())
		return ctx.handle_error(perr)
	}

	return success(mut ctx)
}

fn conduit_user_list(mut app App, mut ctx Context, p UserListParams) veb.Result {
	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	count := model_user_list_count(mut tx, p) or {
		tx.rollback() or {}
		perr := new_error_internal('Failed to retrieve user count', err.msg())
		return ctx.handle_error(perr)
	}

	if count == 0 {
		tx.rollback() or {}
		return ctx.json(UserListResponseEnvelope{
			count:  count
			offset: p.offset
			fetch:  p.fetch
		})
	}

	users := model_user_list(mut tx, p) or {
		tx.rollback() or {}
		perr := new_error_internal('Failed to retrieve users', err.msg())
		return ctx.handle_error(perr)
	}

	tx.rollback() or {
		perr := new_error_internal(error_transaction_commit, err.msg())
		return ctx.handle_error(perr)
	}

	mut external_users := []UserResponse{len: users.len}
	for i := 0; i < users.len; i++ {
		external_users[i] = format_user_response(users[i])
	}

	return ctx.json(UserListResponseEnvelope{
		users:  external_users
		count:  count
		offset: p.offset
		fetch:  p.fetch
	})
}

fn conduit_user_get_by_id(mut app App, mut tx firebird.Transaction, user_id ID) !User {
	p := UserListParams{
		ids:   [user_id]
		fetch: 1
	}

	count := model_user_list_count(mut tx, p) or {
		tx.rollback() or {}
		return new_error_internal('Failed to retrieve user count', err.msg())
	}

	if count == 0 {
		return new_error_not_found('No user found with the given id.', 'count == 0')
	}

	users := model_user_list(mut tx, p) or {
		return new_error_internal('Failed to retrieve users', err.msg())
	}

	user := users[0]
	return user
}

fn conduit_user_get_by_email(mut app App, mut tx firebird.Transaction, email string) !User {
	p := UserListParams{
		email: email
		fetch: 1
	}

	count := model_user_list_count(mut tx, p) or {
		return new_error_internal('Failed to retrieve user count', err.msg())
	}

	if count == 0 {
		log.debug('user count == 0')
		return new_error_login()
	}

	users := model_user_list(mut tx, p) or {
		log.debug(err.msg())
		return new_error_login()
	}

	user := users[0]
	return user
}

