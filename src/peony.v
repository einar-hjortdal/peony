module main

// vlib
import log
import os
import strconv
import veb
// first party
import einar_hjortdal.firebird
import einar_hjortdal.luuid
import einar_hjortdal.sessions

@[heap]
pub struct App {
	veb.Middleware[Context]
mut:
	luuid_generator &luuid.Generator
	fb              &firebird.Connection
	session_store   &sessions.JsonWebTokenStore
}

pub struct Context {
	veb.Context
mut:
	session sessions.Session
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
	mut new_firebird_connection := firebird.new_connection(firebird_url) or { panic(err) }
	mut new_luuid_generator := luuid.new_generator()

	prepare_db(mut new_firebird_connection, mut new_luuid_generator) or { panic(err) }

	mut session_store_options := sessions.JsonWebTokenStoreOptions{
		app_name:  lib
		issuer:    os.getenv(env_instance_number)
		secret:    os.getenv(env_session_secret)
		prefix:    os.getenv(env_session_admin_prefix)
		valid_end: strconv.parse_int(os.getenv(env_session_max_age), 10, 64) or { panic(err) }
	}
	mut session_store := sessions.new_jwt_store(mut session_store_options) or { panic(err) }

	mut app := App{
		luuid_generator: new_luuid_generator
		fb:              new_firebird_connection
		session_store:   session_store
	}

	app.route_use('/admin/:path...', handler: app.load_session_middleware)
	app.route_use('/admin/:path...', handler: app.save_session_middleware, after: true)

	port := os.getenv(env_port).int()
	veb.run[App, Context](mut app, port)
}
