module main

// vlib
import vweb
// local
import models

// admin_store_get retrieves store details
// Requires authorization.
['/admin/store'; get]
pub fn (mut app App) admin_store_get() vweb.Result {
	fn_name := 'admin_store_get'

	_, mut err := app.check_user_auth()
	if err.code() != 0 {
		return app.send_error(err, fn_name)
	}

	store := models.store_retrieve(mut app.db) or { return app.send_error(err, fn_name) }
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
	fn_name := 'admin_store_post'

	_, mut err := app.check_user_auth()
	if err.code() != 0 {
		return app.send_error(err, fn_name)
	}

	store := models.store_retrieve(mut app.db) or { return app.send_error(err, fn_name) }
	// TODO invoke store method
	return app.json(store)
}
