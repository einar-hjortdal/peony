module main

// vlib
import veb
import os
import log
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
	if os.getenv('DEBUG') == 'true' {
		log.set_level(log.Level.debug)
	} else {
		log.set_level(log.Level.info)
	}
}

fn (mut app App) session_middleware(mut ctx Context) bool {
	ctx.session = app.session_store.new(ctx.req, os.getenv('SESSION_NAME'))
	return true
}

fn main() {
	load_settings()
	set_log_level()

	firebird_url := os.getenv(env_firebird_url)
	mut new_firebird_connection := firebird.new_connection(firebird_url) or { panic(err) }
	mut new_luuid_generator := luuid.new_generator()

	prepare_db(mut new_firebird_connection, mut new_luuid_generator) or { panic(err) }

	mut session_store_options := sessions.JsonWebTokenStoreOptions{
		secret: os.getenv('SESSION_SECRET')
	}
	mut session_store := sessions.new_jwt_store(mut session_store_options) or { panic(err) }

	mut app := App{
		luuid_generator: new_luuid_generator
		fb:              new_firebird_connection
		session_store:   session_store
	}
	app.route_use('/admin/:path...', handler: app.session_middleware)

	port := os.getenv(env_port).int()
	veb.run[App, Context](mut app, port)
}
