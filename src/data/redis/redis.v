module redis

// vlib
import os
// first party
import coachonko.redis as c_redis

// https://github.com/Coachonko/redis/blob/meester/src/options.v
fn get_client_options() &c_redis.Options {
	return &c_redis.Options{
		address: os.getenv('REDIS_URL')
		username: os.getenv('REDIS_USERNAME')
		password: os.getenv('REDIS_PASSWORD')
	}
}
