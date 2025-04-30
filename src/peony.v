module main

// vlib
import veb
import os
import log
// first party
import einar_hjortdal.firebird
import einar_hjortdal.luuid
// import einar_hjortdal.sessions

pub struct App {
mut:
	luuid_generator &luuid.Generator
	fb              &firebird.Connection
}

pub struct Context {
	veb.Context
}

// TODO middlwares per-route: check auth where needed, attach user data to context.

fn set_log_level() {
	if os.getenv('DEBUG') == 'true' {
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

	prepare_db(mut new_firebird_connection)!

	mut app := App{
		luuid_generator: new_luuid_generator
		fb:              new_firebird_connection
	}
	port := os.getenv(env_port).int()
	veb.run[App, Context](mut app, port)
}
