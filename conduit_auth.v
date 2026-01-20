module peony

import log
import veb

fn conduit_auth_user(mut app App, mut ctx Context, p AuthRequest) veb.Result {
	up := UserListParams{
		filter_by_email: true
		email:           p.email
		fetch:           1
	}

	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	count := model_user_list_count(mut tx, up) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Failed to retrieve user count', err.msg())
	}

	if count == 0 {
		tx.rollback() or {}
		log.debug('user count == 0')
		return handle_error_login(mut ctx)
	}

	users := model_user_list(mut tx, up) or {
		tx.rollback() or {}
		log.debug(err.msg())
		return handle_error_login(mut ctx)
	}

	tx.rollback() or {}

	user := users[0]
	verify_password(p.password, user.password_hash, user.password_salt) or {
		log.debug(err.msg())
		return handle_error_login(mut ctx)
	}

	ctx.user_session_values = UserSessionValues{
		id:     user.id
		id_bin: user.id_bin
	}

	return success(mut ctx)
}
