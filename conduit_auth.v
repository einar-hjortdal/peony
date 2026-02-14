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
		perr := new_error_internal(error_transaction_start, err.msg())
		return ctx.handle_peony_error(perr)
	}

	count := model_user_list_count(mut tx, up) or {
		tx.rollback() or {}
		perr := new_error_internal('Failed to retrieve user count', err.msg())
		return ctx.handle_peony_error(perr)
	}

	if count == 0 {
		tx.rollback() or {}
		log.debug('user count == 0')
		perr := new_error_login()
		return ctx.handle_peony_error(perr)
	}

	users := model_user_list(mut tx, up) or {
		tx.rollback() or {}
		log.debug(err.msg())
		perr := new_error_login()
		return ctx.handle_peony_error(perr)
	}

	tx.rollback() or {}

	user := users[0]
	verify_password(p.password, user.password_hash, user.password_salt) or {
		log.debug(err.msg())
		perr := new_error_login()
		return ctx.handle_peony_error(perr)
	}

	ctx.user_session_values = UserSessionValues{
		id:     user.id
		id_bin: user.id_bin
	}

	return success(mut ctx)
}
