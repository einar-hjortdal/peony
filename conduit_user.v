module peony

import veb

fn conduit_user_create(mut app App, mut ctx Context, p UserCreateRequest) veb.Result {
	mut tx := app.start_transaction() or {
		perr := new_error_internal(error_transaction_start, err.msg())
		return ctx.handle_peony_error(perr)
	}

	user_id, user_id_bin := app.new_id()

	if image := p.image {
		println('TODO create image: ${image}')
	}

	model_user_create(mut tx, p, user_id, user_id_bin) or {
		tx.rollback() or {}
		perr := new_error_internal('Failed to upload file', err.msg())
		return ctx.handle_peony_error(perr)
	}

	tx.commit() or {
		tx.rollback() or {}
		perr := new_error_internal(error_transaction_commit, err.msg())
		return ctx.handle_peony_error(perr)
	}

	return success(mut ctx)
}

fn conduit_user_update(mut app App, mut ctx Context, user_id_bin []u8, p UserUpdateRequest) veb.Result {
	mut tx := app.start_transaction() or {
		perr := new_error_internal(error_transaction_start, err.msg())
		return ctx.handle_peony_error(perr)
	}

	if image := p.image {
		println('TODO update image: ${image}')
	}

	model_user_update(mut tx, user_id_bin, p) or {
		tx.rollback() or {}
		perr := new_error_internal('Failed to create user', err.msg())
		return ctx.handle_peony_error(perr)
	}

	tx.commit() or {
		tx.rollback() or {}
		perr := new_error_internal(error_transaction_commit, err.msg())
		return ctx.handle_peony_error(perr)
	}

	return success(mut ctx)
}

fn conduit_user_delete(mut app App, mut ctx Context, user_id_bin []u8) veb.Result {
	mut tx := app.start_transaction() or {
		perr := new_error_internal(error_transaction_start, err.msg())
		return ctx.handle_peony_error(perr)
	}

	model_user_delete(mut tx, user_id_bin) or {
		tx.rollback() or {}
		perr := new_error_internal('Failed to delete user', err.msg())
		return ctx.handle_peony_error(perr)
	}

	tx.commit() or {
		tx.rollback() or {}
		perr := new_error_internal(error_transaction_commit, err.msg())
		return ctx.handle_peony_error(perr)
	}

	return success(mut ctx)
}

fn conduit_user_list(mut app App, mut ctx Context, p UserListParams) veb.Result {
	mut tx := app.start_transaction() or {
		perr := new_error_internal(error_transaction_start, err.msg())
		return ctx.handle_peony_error(perr)
	}

	count := model_user_list_count(mut tx, p) or {
		tx.rollback() or {}
		perr := new_error_internal('Failed to retrieve user count', err.msg())
		return ctx.handle_peony_error(perr)
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
		return ctx.handle_peony_error(perr)
	}

	tx.rollback() or {
		perr := new_error_internal(error_transaction_commit, err.msg())
		return ctx.handle_peony_error(perr)
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

fn conduit_user_get_by_id(mut app App, mut ctx Context, user_id_bin []u8) veb.Result {
	p := UserListParams{
		filter_by_id: true
		ids_bin:      [user_id_bin]
		fetch:        1
	}

	mut tx := app.start_transaction() or {
		perr := new_error_internal(error_transaction_start, err.msg())
		return ctx.handle_peony_error(perr)
	}

	count := model_user_list_count(mut tx, p) or {
		tx.rollback() or {}
		perr := new_error_internal('Failed to retrieve user count', err.msg())
		return ctx.handle_peony_error(perr)
	}

	if count == 0 {
		tx.rollback() or {}
		perr := new_error_not_found('No user found with the given id.', 'count == 0')
		return ctx.handle_peony_error(perr)
	}

	users := model_user_list(mut tx, p) or {
		tx.rollback() or {}
		perr := new_error_internal('Failed to retrieve users', err.msg())
		return ctx.handle_peony_error(perr)
	}

	tx.rollback() or {
		perr := new_error_internal(error_transaction_commit, err.msg())
		return ctx.handle_peony_error(perr)
	}

	user := users[0]
	return ctx.json(UserResponseEnvelope{
		user: format_user_response(user)
	})
}
