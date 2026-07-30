module peony

import log
import veb
import einar_hjortdal.firebird
import einar_hjortdal.luuid
import einar_hjortdal.redict
import einar_hjortdal.sessions
import internal.conduit
import providers

// Providers are services used by peony.
// BlobProvider stores and serves files such as product images, videos, etc.
// NotificationProvider allows peony to send email, sms...
// PaymentProvider enables peony to receive payments, issue refunds, etc.
// FulfillmentProvider enables peony to schedule shipments, book returns, etc.
pub struct ProvidersConfig {
pub:
	blob_factory fn () !&providers.BlobProvider @[required]
	notification []providers.NotificationProviderConfig
}

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
		// providers:       // struct with providers configuration
	}

	app.use(handler: app.middleware_debug)
	app.route_use('/admin/:path...', handler: app.middleware_load_user_session)
	app.route_use('/admin/:path...', handler: app.middleware_save_user_session, after: true)
	app.route_use('/store/:path...', handler: app.middleware_get_api_key)
	// app.route_use('/store/:path...', handler: app.middleware_load_store_session)
	// app.route_use('/store/:path...', handler: app.middleware_save_store_session, after: true)

	return app
}

// starts peony
// An error is returned if the initialization fails.
pub fn (mut app App) run() ! {
	app.prepare_db()!
	app.init_providers(p)! // add installed provider data to database
	veb.run[App, Context](mut app, app.config.port)
}
