module config

import os
import utils

// remove_invalid_settings checks if the settings provided are valid: if the provided settings are invalid,
// and these settings have defaults (added with add_default_settings), they are removed from the environment.
fn remove_invalid_settings(prefix string) {
	bool_to_be_parsed := [
		'DEBUG',
	]
	for str in bool_to_be_parsed {
		if !utils.can_parse_bool(os.getenv(prefix + str)) {
			os.unsetenv(prefix + str)
		}
	}
}

// add_default_settings adds any missing setting to the environment.
fn add_default_settings(prefix string) {
	defaults := {
		'DEBUG':                  'false'
		'APP_NAME':               'Peony'
		'INSTANCE_NUMBER':        '0'
		'PORT':                   '29000'
		'SESSION_MAX_AGE':        '86400' // One day
		'SESSION_NAME':           'Session'
		'SESSION_REFRESH_EXPIRE': 'false'
		'SESSION_ADMIN_PREFIX':   'Admin'
		'CACHE_DURATION':         '1800' // 30 minutes
		'ADMIN_URL':              'localhost:29100'
		'STOREFRONT_URL':         'localhost:29200'
		'MYSQL_URL':              '127.0.0.1:29300'
		'REDIS_URL':              'localhost:29400'
		// 'S3_URL': 'localhost:29500'
	}
	for key, val in defaults {
		os.setenv(prefix + key, val, false)
	}
}

// prepare_settings provides the list of expected environment variable keys.
// These keys are expected to be provided with a prefix, this prefix is removed by remove_prefix.
// This list contains all the environment variables used by peony.
fn prepare_settings(prefix string) {
	expected := [
		'DEBUG',
		'APP_NAME',
		'INSTANCE_NUMBER',
		'ADDRESS',
		'PORT',
		'ADMIN_URL',
		'STOREFRONT_URL',
		'CACHE_DURATION',
		'SESSION_MAX_AGE',
		'SESSION_NAME',
		'SESSION_REFRESH_EXPIRE',
		'SESSION_SECRET',
		'SESSION_ADMIN_PREFIX',
		'MYSQL_URL',
		'MYSQL_DATABASE',
		'MYSQL_USER',
		'MYSQL_PASSWORD',
		'REDIS_URL',
		'REDIS_DATABASE',
		'REDIS_USERNAME',
		'REDIS_PASSWORD',
		'S3_URL',
		'S3_BUCKET',
		'S3_ACCESS_KEY',
		'S3_SECRET_KEY',
	]
	// verify_settings(prefix, expected)
	remove_prefix(prefix, expected)
}

// verify_settings verifies all required settings are available in the environment, and panics if any
// is missing.
// TODO
fn verify_settings(prefix string, expected []string) {
	for key in expected {
		if os.getenv(prefix + key) == '' {
			panic('Missing environment variable ${key}')
		}
	}
}

// remove_prefix removes the prefixed variables from the environment,
// replacing them with unprefixed ones.
fn remove_prefix(prefix string, expected []string) {
	for key in expected {
		val := os.getenv(prefix + key)
		os.unsetenv(prefix + key)
		os.setenv(key, val, false)
	}
}

// load_settings reads .env file and loads settings into the environment,
// settings are validated and default settings are set if missing
//
// This function should be called first in the main function
pub fn load_settings() {
	prefix := 'PEONY_'
	load()
	remove_invalid_settings(prefix)
	add_default_settings(prefix)
	prepare_settings(prefix)
}
