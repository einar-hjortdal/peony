module redis

import os
import utils
import coachonko.sessions as c_sessions

pub fn new_sessions_store() !&c_sessions.Store {
	// https://github.com/Coachonko/sessions/blob/meester/src/jwt.v
	mut jwto := c_sessions.JsonWebTokenOptions{
		app_name: os.getenv('APP_NAME')
		issuer: '${os.getenv('APP_NAME')}${os.getenv('INSTANCE_NUMBER')}'
		prefix: '${os.getenv('APP_NAME').title()}-'
		secret: os.getenv('SESSION_SECRET')
		valid_end: utils.number_to_seconds(os.getenv('SESSION_MAX_AGE'))
	}

	// https://github.com/Coachonko/sessions/blob/meester/src/redis_store.v
	mut rso := c_sessions.RedisStoreOptions{
		refresh_expire: utils.is_true(os.getenv('SESSION_REFRESH_EXPIRE'))
	}

	mut ro := get_client_options()

	return c_sessions.new_redis_store_jwt(mut rso, mut jwto, mut ro)!
}

// Session names and store
pub struct Sessions {
pub:
	storefront_name string
	admin_name      string
pub mut:
	store &c_sessions.Store
}

pub fn new_sessions_struct() &Sessions {
	new_store := new_sessions_store() or { panic(err) }
	new_storefront_name := os.getenv('SESSION_NAME')
	admin_prefix := os.getenv('SESSION_ADMIN_PREFIX')
	new_admin_name := '${admin_prefix}-${new_storefront_name}'
	// Custom headers will be:
	// ${os.getenv('APP_NAME').title()}-${os.getenv('SESSION_ADMIN_PREFIX')}-${os.getenv('SESSION_NAME')}
	// ${os.getenv('APP_NAME').title()}-${os.getenv('SESSION_NAME')}
	return &Sessions{
		store: new_store
		storefront_name: new_storefront_name
		admin_name: new_admin_name
	}
}
