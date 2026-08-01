module peony

import log
import veb
import einar_hjortdal.firebird
import einar_hjortdal.luuid
import einar_hjortdal.redict
import einar_hjortdal.sessions
import internal.conduit
import internal.common

// pub const start_mode_api = 'api'
// pub const start_mode_worker = 'worker'
// pub const start_mode_combined = 'combined'
// pub const start_mode_default = start_mode_combined
pub const start_install_providers_default = false
pub const start_seed_default = false
pub const start_listen_default = true

@[heap]
pub struct App {
	veb.Middleware[Context]
	config Config
mut:
	luuid_generator &luuid.Generator
	firebird        &firebird.Client
	redict          &redict.Client
	session_store   &sessions.Store
	providers       &Providers
}

pub struct Context {
	veb.Context
mut:
	api_key             ?conduit.APIKey
	user_session        sessions.Session
	user_session_values UserSessionValues
	// customer_session        sessions.Session
	// customer_session_values CustomerSessionValues
}

// returns the initialized peony App, you can register your custom veb middleware on it.
// An error is returned if config is invalid or if cannot establish a connection to firebird/redict.
pub fn new_peony_app(config Config, p ProvidersConfig) !&App {
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

	luuid_generator := luuid.new_generator()
	firebird_client := firebird.new_client(firebird.ClientConfig{ url: c.firebird_url })!
	redict_client := redict.new_client(ro)!
	session_store := sessions.new_redict_store_cookie_from_redict_client(rso, co, redict_client)

	mut app := &App{
		config:          c
		luuid_generator: luuid_generator
		firebird:        firebird_client
		redict:          redict_client
		session_store:   session_store
		providers:       p.get_providers()!
	}

	app.use(handler: app.middleware_debug)
	app.route_use('/admin/:path...', handler: app.middleware_load_user_session)
	app.route_use('/admin/:path...', handler: app.middleware_save_user_session, after: true)
	app.route_use('/store/:path...', handler: app.middleware_get_api_key)
	// app.route_use('/store/:path...', handler: app.middleware_load_store_session)
	// app.route_use('/store/:path...', handler: app.middleware_save_store_session, after: true)

	return app
}

// StartParams defines how the application behaves:
// install_providers if true then check databse records of providers. Defaults to false.
// mode sets whether the application behaves strictly as api, worker or as the combination of the two. Defaults to 'combined'.
// seed if true then seed database. Defaults to false.
// listen if true then listens to web requests, otherwise exits immediately. Defaults to true.
pub struct StartParams {
pub:
	install_providers ?bool
	// mode              ?string
	seed   ?bool
	listen ?bool
}

fn (p StartParams) validate() ! {
	// if mode := p.mode {
	// 	match mode {
	// 		start_mode_api, start_mode_worker, start_mode_combined {}
	// 		else { return error('invalid mode `${mode}`') }
	// 	}
	// }
}

pub fn (mut app App) run(params ?StartParams) ! {
	p := params or { StartParams{} }
	p.validate()!

	if common.bool_or(p.seed, start_seed_default) {
		app.prepare_db()!
	}

	if common.bool_or(p.install_providers, start_install_providers_default) {
		app.init_providers()!
	}

	if common.bool_or(p.listen, start_listen_default) {
		// _ := common.unwrap_option_or(p.mode, start_mode_default)
		// TODO handle mode (implement worker mode)
		veb.run[App, Context](mut app, app.config.port)
	}
}
