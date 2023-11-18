module main

// vlib
import vweb
// local
import models
import json

// admin_store_get retrieves store details
// Requires authorization.
@['/admin/store'; get]
pub fn (mut app App) admin_store_get() vweb.Result {
	fn_name := 'admin_store_get'

	app.check_user_auth() or { return app.send_error(err, fn_name) }

	store := models.store_retrieve(mut app.db) or { return app.send_error(err, fn_name) }
	return app.json(store)
}

// admin_store_post updates store details
// Requires authorization.
@['/admin/store/:id'; post]
pub fn (mut app App) admin_store_post(id string) vweb.Result {
	fn_name := 'admin_store_post'

	app.check_user_auth() or { return app.send_error(err, fn_name) }

	body := json.decode(models.StoreWriteable, app.req.data) or {
		return app.send_error(err, fn_name)
	}

	body.update(mut app.db, id) or { return app.send_error(err, fn_name) }

	updated_store := models.store_retrieve(mut app.db) or { return app.send_error(err, fn_name) }

	return app.json(updated_store)
}
