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
	_, mut e := app.check_user_auth()
	if e.code != 0 {
		app.set_status(401, 'Unauthorized')
		return app.json(e)
	}

	users := models.user_list(mut app.db) or {
		app.set_status(500, 'Internal server error')
		e = new_peony_error(5, err.msg())
		return app.json(e)
	}
	return app.json(users)
}

struct AdminUsersPostRequest {
mut:
	email      string // required
	password   string // required
	handle     string
	first_name string
	last_name  string
	role       string // must be either 'admin', 'member', 'developer' or 'author'
}

// admin_users_post creates a user
// Requires authorization.
['/admin/users'; post]
pub fn (mut app App) admin_users_post() vweb.Result {
	_, mut e := app.check_user_auth()
	if e.code != 0 {
		app.set_status(401, 'Unauthorized')
		return app.json(e)
	}

	mut body := json.decode(AdminUsersPostRequest, app.req.data) or {
		app.set_status(422, 'Invalid request')
		e = new_peony_error(5, 'Could not decode AdminUsersPostRequest')
		return app.json(e)
	}

	if body.handle == '' {
		body.handle = app.luuid_generator.v2() or {
			app.set_status(500, 'Internal server error')
			peony_error := new_peony_error(500, err.msg())
			return app.json(peony_error)
		}
	}

	email := body.email.trim_space()
	validate_email(email) or {
		app.set_status(400, 'Invalid request')
		e = new_peony_error(400, err.msg())
		return app.json(e)
	}

	utils.validate_password(body.password) or {
		app.set_status(422, 'Invalid request')
		e = new_peony_error(5, err.msg())
		return app.json(e)
	}

	password_hash := utils.new_password_hash(body.password) or {
		app.set_status(500, 'Internal server error')
		peony_error := new_peony_error(500, err.msg())
		return app.json(peony_error)
	}

	mut new_user := models.UserWriteable{
		email: email
		password_hash: password_hash
	}

	id := app.luuid_generator.v2() or {
		app.set_status(500, 'Internal server error')
		peony_error := new_peony_error(500, err.msg())
		return app.json(peony_error)
	}

	first_name := body.first_name.trim_space()
	if first_name != '' {
		new_user.first_name = first_name
	}

	last_name := body.last_name.trim_space()
	if last_name != '' {
		new_user.last_name = last_name
	}

	role := body.role.trim_space()
	if role != '' {
		match role {
			'admin', 'member', 'developer', 'author' {
				new_user.role = role
			}
			else {
				app.set_status(422, 'Invalid request')
				e = new_peony_error(5, "role must be either 'admin', 'member', 'developer' or 'author'")
				return app.json(e)
			}
		}
	}

	new_user.create(mut app.db, id) or {
		app.set_status(500, 'Internal server error')
		e = new_peony_error(5, err.msg())
		return app.json(e)
	}

	created_user := models.user_retrieve_by_email(mut app.db, email) or {
		app.set_status(500, 'Internal server error')
		e = new_peony_error(5, err.msg())
		return app.json(e)
	}
	return app.json(created_user)
}

// Requires authorization.
['/admin/users/:id'; get]
pub fn (mut app App) admin_users_id_get(id string) vweb.Result {
	_, mut e := app.check_user_auth()
	if e.code != 0 {
		app.set_status(401, 'Unauthorized')
		return app.json(e)
	}

	user := models.user_retrieve_by_id(mut app.db, id) or {
		app.set_status(500, 'Internal server error')
		e = new_peony_error(5, err.msg())
		return app.json(e)
	}
	return app.json(user)
}

struct AdminUsersIdPostRequest {
	first_name string
	last_name  string
	role       string // must be either 'admin', 'member', 'developer' or 'author'
	metadata   string
}

// Requires authorization.
// Note: do not accept changes to id, deleted_at
['/admin/user/:id'; post]
pub fn (mut app App) admin_users_id_post(id string) vweb.Result {
	mut v, mut e := app.check_user_auth()
	if e.code != 0 {
		app.set_status(401, 'Unauthorized')
		return app.json(e)
	}

	body := json.decode(AdminUsersIdPostRequest, app.req.data) or {
		app.set_status(422, 'Invalid request')
		e = new_peony_error(5, 'Could not decode AdminUsersIdPostRequest')
		return app.json(e)
	}

	mut user := models.user_retrieve_by_id(mut app.db, id) or {
		app.set_status(500, 'Internal server error')
		e = new_peony_error(5, err.msg())
		return app.json(e)
	}

	first_name := body.first_name.trim_space()
	if first_name != '' {
		user.first_name = first_name
	}

	last_name := body.last_name.trim_space()
	if last_name != '' {
		user.last_name = last_name
	}

	role := body.role.trim_space()
	if role != '' {
		match role {
			'admin', 'member', 'developer', 'author' {
				user.role = role
			}
			else {
				app.set_status(422, 'Invalid request')
				e = new_peony_error(5, "role must be either 'admin', 'member', 'developer' or 'author'")
				return app.json(e)
			}
		}
	}

	user.update(mut app.db) or {
		app.set_status(500, 'Internal server error')
		e = new_peony_error(5, err.msg())
		return app.json(e)
	}

	if v.user.id == id {
		v.user = user
		e = app.save_admin_session(v)
		if e.code != 0 {
			app.logger.debug(e.data)
			app.set_status(500, 'Internal server error')
			return app.json(e)
		}
	}

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
	v, mut e := app.check_user_auth()
	if e.code != 0 {
		app.set_status(401, 'Unauthorized')
		return app.json(e)
	}

	// TODO do not delete last user. Check if number of non-delete users is >1

	models.user_delete_by_id(mut app.db, id) or {
		app.set_status(500, 'Internal server error')
		e = new_peony_error(5, err.msg())
		return app.json(e)
	}

	user := models.user_retrieve_by_id(mut app.db, id) or {
		app.set_status(500, 'Internal server error')
		e = new_peony_error(5, err.msg())
		return app.json(e)
	}

	if v.user.id == id {
		e = app.delete_admin_session()
		if e.code != 0 {
			app.logger.debug(e.data)
			app.set_status(500, 'Internal server error')
			return app.json(e)
		}
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
// 	if e.code != 0 {
// 		app.set_status(401, 'Unauthorized')
// 		return app.json(e)
// 	}

// 	body := json.decode(AdminUsersPasswordtokenPostRequest, app.req.data) or {
// 		app.set_status(422, 'Invalid request')
// 		e = new_peony_error(5, 'Could not decode AdminUsersPasswordtokenPostRequest')
// 		return app.json(e)
// 	}

// 	email := body.email.trim_space()
// 	validate_email(email) or {
// 		app.set_status(422, 'Invalid request')
// 		e = new_peony_error(5, err.msg())
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
// 	if e.code != 0 {
// 		app.set_status(401, 'Unauthorized')
// 		return app.json(e)
// 	}

// 	body := json.decode(AdminUsersPasswordresetPostRequest, app.req.data) or {
// 		app.set_status(422, 'Invalid request')
// 		e = new_peony_error(5, 'Could not decode AdminUsersPasswordresetPostRequest')
// 		return app.json(e)
// 	}

// 	if body.token == '' {
// 		app.set_status(422, 'Invalid request')
// 		e = new_peony_error(5, 'Invalid token')
// 		return app.json(e)
// 	}

// 	password := body.password.trim_space()
// 	validate_password(password) or {
// 		app.set_status(422, 'Invalid request')
// 		e = new_peony_error(5, 'Invalid password')
// 		return app.json(e)
// 	}

// 	// TODO get email from cache, error if cache entry is missing
// 	// TODO update user password, add model method

// 	return app.json(u)
// }
