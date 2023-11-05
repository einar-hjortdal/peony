module redis

import utils
import coachonko.cache as c_cache
import os

pub fn new_cache_store() !&c_cache.Store {
	rso := c_cache.RedisStoreOptions{
		expire: utils.number_to_seconds(os.getenv('CACHE_DURATION'))
	}
	mut ro := get_client_options()
	return c_cache.new_redis_store(rso, mut ro)!
}
