module main

// vlib
import vweb
import runtime
import os
import db.mysql as v_mysql
import log
import net.http
// local
import config
import data.mysql
import data.redis
import utils
// first party
import coachonko.luuid
import coachonko.cache as c_cache
import coachonko.sessions as c_sessions

// https://github.com/vlang/v/issues/14952
// must run peony like so on Euro Linux 9:
// v -cflags "-I/usr/include/mysql" run .

/*
*
* App
*
*/

struct App {
	vweb.Context
	db_handle vweb.DatabasePool[v_mysql.DB] = unsafe { nil }
mut:
	logger          log.Log
	luuid_generator &luuid.Generator   @[vweb_global]
	cache_store     &c_cache.Store     @[vweb_global]
	sessions        &redis.Sessions    @[vweb_global]
	session         c_sessions.Session
	db              v_mysql.DB
}

// TODO middleware:
// middlwares per-route: check auth where needed, attach user data to context.
// https://github.com/vlang/v/tree/master/vlib/vweb#middleware
// https://github.com/vlang/v/tree/master/vlib/vweb#context-values

pub fn (mut app App) before_request() {
	handle_cors(mut app)
	// Send response automatically to all OPTIONS (preflight) requests.
	if app.req.method == http.Method.options {
		app.ok('')
	}
}

fn handle_cors(mut app App) {
	admin_url := os.getenv('ADMIN_URL')
	storefront_url := os.getenv('STOREFRONT_URL')
	origin := app.get_header('Origin')

	if origin == storefront_url || origin == admin_url {
		admin_header := '${os.getenv('APP_NAME').title()}-${os.getenv('SESSION_ADMIN_PREFIX')}-${os.getenv('SESSION_NAME')}'
		storefront_header := '${os.getenv('APP_NAME').title()}-${os.getenv('SESSION_NAME')}'
		app.add_header('Access-Control-Allow-Origin', origin)
		app.add_header('Access-Control-Allow-Methods', 'DELETE')
		app.add_header('Access-Control-Allow-Headers', 'Content-Type, ${admin_header}, ${storefront_header}')
		app.add_header('Access-Control-Expose-Headers', '${admin_header}, ${storefront_header}')
	}
}

/*
*
* Main
*
*/

fn main() {
	cpus := runtime.nr_cpus()
	config.load_settings()
	mut new_peony_logger := utils.create_logger()
	prepare_db(mut new_peony_logger)
	mysql_pool := vweb.database_pool(handler: mysql.new_mysql_conn, nr_workers: cpus)

	mut new_luuid_generator := luuid.new_generator()

	mut new_cache_store := redis.new_cache_store() or { panic(err) }
	mut new_sessions_struct := redis.new_sessions_struct()

	mut peony_app := &App{
		db_handle: mysql_pool
		logger: new_peony_logger
		luuid_generator: new_luuid_generator
		sessions: new_sessions_struct
		cache_store: new_cache_store
	}

	vweb_params := vweb.RunParams{
		host: os.getenv('ADDRESS')
		port: os.getenv('PORT').int()
		nr_workers: cpus
	}

	// Start peony
	vweb.run_at(peony_app, vweb_params) or {
		panic(err)
		return
	}
}
