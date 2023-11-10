module main

// vlib
import json
// local
import models
import utils

/*
*
* Admin sessions
*
*/

// AdminValues is the struct that will be encoded to json and saved in `c_sessions.Session.values`.
// The presence of data in the user struct signals that the session is authenticated.
struct AdminValues {
mut:
	user models.User
}

fn (v AdminValues) encode() string {
	return json.encode(v)
}

fn decode_values(s string) AdminValues {
	if values := json.decode(AdminValues, s) {
		return values
	} else {
		return AdminValues{}
	}
}

// new_admin_session wraps `c_sessions.Store.new`.
fn (mut app App) new_admin_session() AdminValues {
	app.session = app.sessions.store.new(app.req, app.sessions.admin_name)
	return decode_values(app.session.values)
}

// save_admin_session wraps `c_sessions.Store.save`.
fn (mut app App) save_admin_session(values AdminValues) ! {
	app.session.values = values.encode()
	app.sessions.store.save(mut app.header, mut app.session) or {
		return utils.new_peony_error(500, 'Could not save session')
	}
}

// delete_admin_session sets `c_sessions.Session.to_prune` to `true` and invokes `c_sessions.Store.save`.
fn (mut app App) delete_admin_session() ! {
	app.session.to_prune = true
	app.sessions.store.save(mut app.header, mut app.session) or {
		return utils.new_peony_error(500, 'Could not save session')
	}
}

// TODO wrap c_sessions.Session.flashes

fn (mut app App) auth_user(mut values AdminValues, email string, password string) ! {
	password_hash := models.user_password_hash_by_email(mut app.db, email) or {
		return utils.new_peony_error(400, err.msg())
	}
	utils.verify_password(password, password_hash) or {
		return utils.new_peony_error(400, 'User does not exist or invalid credentials')
	}
	retrieved_user := models.user_retrieve_by_email(mut app.db, email) or {
		return utils.new_peony_error(500, err.msg())
	}
	values.user = retrieved_user
}

// check_user_auth verifies that an admin session is authenticated.
// If the session is authenticated, AdminValues are returned together with a nil PeonyError.
// Otherwise, an empty AdminValues is returned together with a PeonyError.
// TODO just return !AdminValues, PeonyError implements IError interface
fn (mut app App) check_user_auth() (AdminValues, utils.PeonyError) {
	v := app.new_admin_session()
	if v.user.id == '' {
		return v, utils.new_peony_error(401, 'User data is missing')
	}
	return v, utils.new_peony_error(0, '')
}

/*
*
* Customer sessions
*
*/
