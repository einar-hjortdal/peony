module main

// vlib
import vweb
// local
import models

// admin_store_get retrieves store details
// Requires authorization.
['/admin/store'; get]
pub fn (mut app App) admin_store_get() vweb.Result {
	_, mut e := app.check_user_auth()
	if e.code != 0 {
		app.set_status(401, 'Unauthorized')
		return app.json(e)
	}

	store := models.store_retrieve(mut app.db) or {
		app.set_status(500, 'Internal server error')
		e = new_peony_error(5, err.msg())
		return app.json(e)
	}
	return app.json(store)
}

struct AdminStorePostRequest {
	name                  string
	default_locale_code   string
	default_currency_code string
	swap_link_template    string
	payment_link_template string
	invite_link_template  string
	// currencies []string
	metadata string
}

// admin_store_post updates store details
// Requires authorization.
['/admin/store'; post]
pub fn (mut app App) admin_store_post() vweb.Result {
	_, mut e := app.check_user_auth()
	if e.code != 0 {
		app.set_status(401, 'Unauthorized')
		return app.json(e)
	}

	store := models.store_retrieve(mut app.db) or {
		app.set_status(500, 'Internal server error')
		e = new_peony_error(5, err.msg())
		return app.json(e)
	}
	// TODO validate input and invoke store method
	return app.json(store)
}
