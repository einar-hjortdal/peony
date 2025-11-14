module peony

import log
import net.http
import os
import strconv
import time
import veb
import einar_hjortdal.firebird
import einar_hjortdal.luuid
import einar_hjortdal.redict
import einar_hjortdal.sessions

@[heap]
pub struct App {
	veb.Middleware[Context]
	blob_provider &BlobProvider
	// tax_provider &TaxProvider
	// email_provider &EmailProvider
	// payment_providers []&PaymentProvider
	// fulfillment_providers []&FulfillmentProvider
mut:
	luuid_generator &luuid.Generator
	firebird        &firebird.Connection
	redict          &redict.Client
	session_store   &sessions.Store
}

pub struct Context {
	veb.Context
mut:
	user_session        sessions.Session
	user_session_values UserSessionValues
	// customer_session        sessions.Session
	// customer_session_values CustomerSessionValues
}

fn set_log_level() {
	if os.getenv(env_debug) == 'true' {
		log.set_level(log.Level.debug)
	} else {
		log.set_level(log.Level.info)
	}
}

// returns the initialized peony App, you can register your custom veb middleware on it.
pub fn new_peony_app(blob_provider &BlobProvider) &App {
	load_settings()
	set_log_level()

	firebird_url := os.getenv(env_firebird_url)

	rso := sessions.RedictStoreOptions{
		refresh_expire: parse_bool(os.getenv(env_session_refresh_expire))
	}
	co := sessions.CookieOptions{
		http_only: true
		secret:    os.getenv(env_session_secret)
		secure:    true
		path:      '/'
		max_age:   time.second * strconv.parse_int(os.getenv(env_session_max_age), 10,
			64) or { panic(err) }
	}
	ro := redict.Options{
		url: os.getenv(env_redict_url)
	}

	firebird_connection := firebird.new_connection(firebird_url) or { panic(err) }
	redict_client := redict.new_client(ro) or { panic(err) }
	session_store := sessions.new_redict_store_cookie_from_redict_client(rso, co, redict_client)

	mut app := &App{
		blob_provider:   blob_provider
		luuid_generator: luuid.new_generator()
		firebird:        firebird_connection
		redict:          redict_client
		session_store:   session_store
	}

	app.use(handler: app.middleware_debug)
	app.use(veb.cors[Context](veb.CorsOptions{
		origins:           [os.getenv(env_admin_url)]
		allow_credentials: true
		allowed_methods:   [http.Method.get, http.Method.post, http.Method.delete]
	}))
	app.route_use('/admin/:path...', handler: app.middleware_load_user_session)
	app.route_use('/admin/:path...', handler: app.middleware_save_user_session, after: true)
	// app.route_use('/store/:path...', handler: app.middleware_load_store_session)
	// app.route_use('/store/:path...', handler: app.middleware_save_store_session, after: true)

	return app
}

// starts peony
pub fn (mut app App) run() {
	app.prepare_db()

	port := os.getenv(env_port).int()
	veb.run[App, Context](mut app, port)
}
