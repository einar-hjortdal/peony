module main

// vlib
import vweb
import json
// local
import utils

// admin_auth_get gets the currently logged in User.
// Requires authorization.
['/admin/auth'; get]
pub fn (mut app App) admin_auth_get() vweb.Result {
	v, e := app.check_user_auth()
	if e.code() != 0 {
		app.logger.debug(e.to_string())
		app.set_status(401, 'Unauthorized')
		return app.json(e)
	} else {
		return app.json(v.user)
	}
}

struct AdminAuthPostRequest {
	email    string
	password string
}

// admin_auth_post logs a User in and authorizes them to manage store settings.
['/admin/auth'; post]
pub fn (mut app App) admin_auth_post() vweb.Result {
	body := json.decode(AdminAuthPostRequest, app.req.data) or {
		app.logger.debug(err.msg())
		app.set_status(422, 'Invalid request')
		e := utils.new_peony_error(5, 'Could not decode AdminAuthPostRequest')
		return app.json(e)
	}
	email := body.email.trim_space()

	if email == '' || body.password == '' {
		app.set_status(422, 'Invalid request')
		e := utils.new_peony_error(5, 'AdminAuthPostRequest fields cannot be empty')
		return app.json(e)
	}

	validate_email(email) or {
		app.logger.debug(err.msg())
		app.set_status(422, 'Invalid request')
		e := utils.new_peony_error(5, err.msg())
		return app.json(e)
	}

	mut v, mut e := app.check_user_auth()
	if e.code() != 0 {
		// Handle unauthenticated sessions
		e = app.auth_user(mut v, email, body.password)
		if e.code() != 0 {
			app.logger.debug(e.to_string())
			app.set_status(401, e.data())
			return app.json(e)
		}

		e = app.save_admin_session(v)
		if e.code() != 0 {
			app.logger.debug(e.to_string())
			app.set_status(500, e.data())
			return app.json(e)
		}

		return app.json(v.user)
	} else {
		// Handle authenticated sessions
		e = utils.new_peony_error(5, 'User already logged in')
		app.set_status(409, e.data())
		return app.json(e)
	}
}

// admin_auth_del deletes the current session for the logged in user.
// Requires authorization.
['/admin/auth'; delete]
pub fn (mut app App) admin_auth_delete() vweb.Result {
	_, mut e := app.check_user_auth()
	if e.code() != 0 {
		app.logger.debug(e.to_string())
		app.set_status(401, 'Unauthorized')
		return app.json(e)
	}

	e = app.delete_admin_session()
	if e.code() != 0 {
		app.logger.debug(e.to_string())
		app.set_status(500, 'Could not save session')
		return app.json(e)
	}

	return app.ok('session deleted')
}
