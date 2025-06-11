module main

// vlib
import log
import net.http
import os
import strconv
import time
import veb
// first party
import einar_hjortdal.firebird
import einar_hjortdal.luuid
import einar_hjortdal.redict
import einar_hjortdal.sessions

@[heap]
pub struct App {
	veb.Middleware[Context]
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

fn main() {
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
		max_age:   time.second * strconv.parse_int(os.getenv(env_session_max_age), 10,
			64)!
	}
	ro := redict.Options{
		url: os.getenv(env_redict_url)
	}

	mut app := App{
		luuid_generator: luuid.new_generator()
		firebird:        firebird.new_connection(firebird_url) or { panic(err) }
		redict:          redict.new_client(ro) or { panic(err) }
		session_store:   sessions.new_redict_store_cookie(rso, co, ro) or { panic(err) }
	}

	app.route_use('/admin/:path...', handler: app.load_user_session_middleware)
	app.route_use('/admin/:path...', handler: app.save_user_session_middleware, after: true)

	app.prepare_db()

	app.use(veb.cors[Context](veb.CorsOptions{
		origins:           [os.getenv(env_admin_url)]
		allow_credentials: true
		allowed_methods:   [http.Method.get, http.Method.post, http.Method.delete]
	}))

	port := os.getenv(env_port).int()
	veb.run[App, Context](mut app, port)
}
