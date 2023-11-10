module main

// vlib
import vweb
// local
import models
import json
import utils

// admin_users_get retrieves all users
// Requires authorization.
['/admin/users'; get]
pub fn (mut app App) admin_users_get() vweb.Result {
	fn_name := 'admin_users_get'
	_, mut err := app.check_user_auth()
	if err.code() != 0 {
		return app.send_error(err, fn_name)
	}

	users := models.user_list(mut app.db) or { return app.send_error(err, fn_name) }
	return app.json(users)
}

struct AdminUsersPostRequest {
mut:
	email    string
	password string
	role     string
}

// admin_users_post creates a user
// Requires authorization.
['/admin/users'; post]
pub fn (mut app App) admin_users_post() vweb.Result {
	fn_name := 'admin_users_post'

	_, mut err := app.check_user_auth()
	if err.code() != 0 {
		return app.send_error(err, fn_name)
	}

	mut body := json.decode(AdminUsersPostRequest, app.req.data) or {
		return app.send_error(err, fn_name)
	}

	email := body.email.trim_space()
	validate_email(email) or { return app.send_error(err, fn_name) }

	utils.validate_password(body.password) or { return app.send_error(err, fn_name) }

	password_hash := utils.new_password_hash(body.password) or {
		return app.send_error(err, fn_name)
	}

	id := app.luuid_generator.v2() or { return app.send_error(err, fn_name) }
	handle := app.luuid_generator.v2() or { return app.send_error(err, fn_name) }

	role := body.role.trim_space()
	if role == '' {
		err = utils.new_peony_error(400, 'role is required')
		return app.send_error(err, fn_name)
	}
	if role !in models.allowed_role {
		err = utils.new_peony_error(400, 'role invalid')
		return app.send_error(err, fn_name)
	}

	mut new_user := models.UserWriteable{
		handle: handle
		email: email
		password_hash: password_hash
		role: role
	}

	new_user.create(mut app.db, id) or { return app.send_error(err, fn_name) }

	created_user := models.user_retrieve_by_id(mut app.db, id) or {
		return app.send_error(err, fn_name)
	}
	return app.json(created_user)
}

// Requires authorization.
['/admin/users/:id'; get]
pub fn (mut app App) admin_users_id_get(id string) vweb.Result {
	fn_name := 'admin_users_id_get'
	_, mut err := app.check_user_auth()
	if err.code() != 0 {
		return app.send_error(err, fn_name)
	}

	user := models.user_retrieve_by_id(mut app.db, id) or { return app.send_error(err, fn_name) }
	return app.json(user)
}

// Requires authorization.
['/admin/users/:id'; post]
pub fn (mut app App) admin_users_id_post(id string) vweb.Result {
	fn_name := 'admin_users_id_post'

	mut v, mut err := app.check_user_auth()
	if err.code() != 0 {
		return app.send_error(err, fn_name)
	}

	mut body := json.decode(models.UserWriteable, app.req.data) or {
		return app.send_error(err, fn_name)
	}

	// Generate random handle instead of failing if needed
	if body.handle == '' {
		body.handle = app.luuid_generator.v2() or { return app.send_error(err, fn_name) }
	}

	body.update(mut app.db, id) or { return app.send_error(err, fn_name) }

	if v.user.id == id {
		app.save_admin_session(v) or { return app.send_error(err, fn_name) }
	}

	user := models.user_retrieve_by_id(mut app.db, id) or { return app.send_error(err, fn_name) }

	return app.json(user)
}

struct AdminUsersIdGetDelResponse {
	id      string
	deleted bool
}

// admin_users_id_get deletes a user
// Requires authorization.
['/admin/users/:id'; delete]
pub fn (mut app App) admin_users_id_del(id string) vweb.Result {
	fn_name := 'admin_users_id_del'

	v, mut err := app.check_user_auth()
	if err.code() != 0 {
		return app.send_error(err, fn_name)
	}

	// TODO do not delete last user. Check if number of non-delete users is >1

	models.user_delete_by_id(mut app.db, id) or { return app.send_error(err, fn_name) }

	user := models.user_retrieve_by_id(mut app.db, id) or { return app.send_error(err, fn_name) }

	if v.user.id == id {
		app.delete_admin_session() or { return app.send_error(err, fn_name) }
	}

	return app.json(user)
}

struct AdminUsersPasswordtokenPostRequest {
	email string // required
}

// // admin_users_post_passwordtoken generates a password token for a User with a given email.
// // Note that this endpoint requires authorization. There currently exists no way to generate a password
// // without having a valid authenticated session.
// // Requires authorization.
// ['/admin/users/password-token'; post]
// pub fn (mut app App) admin_users_post_passwordtoken() vweb.Result {
// 	_, mut e := app.check_user_auth()
// 	if e.code() != 0 {
// 		app.set_status(401, 'Unauthorized')
// 		return app.json(e)
// 	}

// 	body := json.decode(AdminUsersPasswordtokenPostRequest, app.req.data) or {
// 		app.set_status(422, 'Invalid request')
// 		e = utils.new_peony_error(5, 'Could not decode AdminUsersPasswordtokenPostRequest')
// 		return app.json(e)
// 	}

// 	email := body.email.trim_space()
// 	validate_email(email) or {
// 		app.set_status(422, 'Invalid request')
// 		e = utils.new_peony_error(5, err.msg())
// 		return app.json(e)
// 	}

// 	// TODO generate token and send via email, store token and email in cache
// 	// Always return ok, do not leak whether an email address has a password or not.

// 	return app.ok('')
// }

// struct AdminUsersPasswordresetPostRequest {
// 	token    string // required
// 	password string // required
// }

// // admin_users_post_passwordreset sets the password for a User given the correct token.
// // Requires authorization.
// ['/admin/users/password-reset'; post]
// pub fn (mut app App) admin_users_post_passwordreset() vweb.Result {
// 	v, mut e := app.check_user_auth()
// 	if e.code() != 0 {
// 		app.set_status(401, 'Unauthorized')
// 		return app.json(e)
// 	}

// 	body := json.decode(AdminUsersPasswordresetPostRequest, app.req.data) or {
// 		app.set_status(422, 'Invalid request')
// 		e = utils.new_peony_error(5, 'Could not decode AdminUsersPasswordresetPostRequest')
// 		return app.json(e)
// 	}

// 	if body.token == '' {
// 		app.set_status(422, 'Invalid request')
// 		e = utils.new_peony_error(5, 'Invalid token')
// 		return app.json(e)
// 	}

// 	password := body.password.trim_space()
// 	validate_password(password) or {
// 		app.set_status(422, 'Invalid request')
// 		e = utils.new_peony_error(5, 'Invalid password')
// 		return app.json(e)
// 	}

// 	// TODO get email from cache, error if cache entry is missing
// 	// TODO update user password, add model method

// 	return app.json(u)
// }
