module main

// vlib
import vweb
import json
// local
import utils

// admin_auth_get gets the currently logged in User.
// Requires authorization.
@['/admin/auth'; get]
pub fn (mut app App) admin_auth_get() vweb.Result {
	fn_name := 'admin_auth_get'
	v, err := app.check_user_auth()
	if err.code() != 0 {
		return app.send_error(err, fn_name)
	}

	return app.json(v.user)
}

struct AdminAuthPostRequest {
	email    string
	password string
}

// admin_auth_post logs a User in and authorizes them to manage store settings.
@['/admin/auth'; post]
pub fn (mut app App) admin_auth_post() vweb.Result {
	fn_name := 'admin_auth_post'

	body := json.decode(AdminAuthPostRequest, app.req.data) or {
		return app.send_error(err, fn_name)
	}
	email := body.email.trim_space()

	if email == '' || body.password == '' {
		err := utils.new_peony_error(400, 'AdminAuthPostRequest fields cannot be empty')
		return app.send_error(err, fn_name)
	}

	validate_email(email) or { return app.send_error(err, fn_name) }

	mut v, mut err := app.check_user_auth()
	if err.code() != 0 {
		// Handle unauthenticated sessions
		app.auth_user(mut v, email, body.password) or { return app.send_error(err, fn_name) }

		app.save_admin_session(v) or { return app.send_error(err, fn_name) }

		return app.json(v.user)
	} else {
		// Handle authenticated sessions
		err = utils.new_peony_error(5, 'User already logged in')
		return app.send_error(err, fn_name)
	}
}

// admin_auth_del deletes the current session for the logged in user.
// Requires authorization.
@['/admin/auth'; delete]
pub fn (mut app App) admin_auth_delete() vweb.Result {
	fn_name := 'admin_auth_delete'

	_, mut err := app.check_user_auth()
	if err.code() != 0 {
		return app.send_error(err, fn_name)
	}

	app.delete_admin_session() or { return app.send_error(err, fn_name) }

	return app.ok('session deleted')
}
