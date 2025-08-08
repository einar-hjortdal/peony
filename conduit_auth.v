module peony

import log
import veb

fn conduit_auth_user(mut app App, mut ctx Context, p AuthRequest) veb.Result {
	user := app.retrieve_user_by_email(p.email) or {
		log.debug(err.msg())
		return handle_login_error(mut ctx)
	}

	verify_password(p.password, user.password_hash, user.password_salt) or {
		log.debug(err.msg())
		return handle_login_error(mut ctx)
	}

	ctx.user_session_values = UserSessionValues{
		id:     user.id
		id_bin: user.id_bin
	}

	return success(mut ctx)
}
