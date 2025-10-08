module peony

import veb

fn conduit_user_create(mut app App, mut ctx Context, p UserCreateRequest) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	user_id, user_id_bin := app.new_id()

	if image := p.image {
		println('TODO create image: ${image}')
	}

	model_user_create(mut tx, p, user_id, user_id_bin) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Failed to create user', err.msg())
	}

	tx.commit() or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, error_transaction_commit, err.msg())
	}

	return success(mut ctx)
}

fn conduit_user_update(mut app App, mut ctx Context, user_id_bin []u8, p UserUpdateRequest) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	if image := p.image {
		println('TODO update image: ${image}')
	}

	model_user_update(mut tx, user_id_bin, p) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Failed to create user', err.msg())
	}

	tx.commit() or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, error_transaction_commit, err.msg())
	}

	return success(mut ctx)
}

fn conduit_user_delete(mut app App, mut ctx Context, user_id_bin []u8) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	model_user_delete(mut tx, user_id_bin) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Failed to delete user', err.msg())
	}

	tx.commit() or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, error_transaction_commit, err.msg())
	}

	return success(mut ctx)
}
