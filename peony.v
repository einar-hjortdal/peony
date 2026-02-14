module peony

import json
import log
import net.http
import veb
import einar_hjortdal.firebird
import einar_hjortdal.luuid
import einar_hjortdal.redict
import einar_hjortdal.sessions

@[heap]
pub struct App {
	veb.Middleware[Context]
	config    Config
	providers &Providers
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

fn (mut ctx Context) handle_peony_error(error PeonyError) veb.Result {
	ctx.res.set_status(error.status_code)
	return ctx.json(json.encode(PeonyErrorResponse{
		message: error.message
		details: error.details
	}))
}

fn (mut ctx Context) handle_error(error IError) veb.Result {
	if error is PeonyError {
		return ctx.handle_peony_error(error)
	}
	return ctx.handle_peony_error(new_error_internal('Unhandled error', error.msg()))
}

// returns the initialized peony App, you can register your custom veb middleware on it.
// An error is returned if config is invalid or if cannot establish a connection to firebird/redict.
pub fn new_peony_app(config Config, providers &Providers) !&App {
	c := config.verify()!

	if c.debug {
		log.set_level(log.Level.debug)
	} else {
		log.set_level(log.Level.info)
	}

	rso := sessions.RedictStoreOptions{
		refresh_expire: c.session_refresh_expire
	}

	co := sessions.CookieOptions{
		http_only: true
		secret:    c.session_secret
		secure:    true
		path:      '/'
		max_age:   c.session_max_age
	}

	ro := redict.Options{
		url: c.redict_url
	}

	firebird_connection := firebird.new_connection(c.firebird_url)!
	redict_client := redict.new_client(ro)!
	session_store := sessions.new_redict_store_cookie_from_redict_client(rso, co, redict_client)

	mut app := &App{
		config:          c
		providers:       providers
		luuid_generator: luuid.new_generator()
		firebird:        firebird_connection
		redict:          redict_client
		session_store:   session_store
	}

	app.use(handler: app.middleware_debug)
	app.use(veb.cors[Context](veb.CorsOptions{
		origins:           [c.admin_frontend_url]
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
// An error is returned if the initialization fails.
pub fn (mut app App) run() ! {
	app.prepare_db()!
	veb.run[App, Context](mut app, app.config.port)
}
