module main

import arrays
import os
import einar_hjortdal.dotenv

const env_prefix = lib.to_upper() + '_'

const env_email = 'EMAIL'
const env_password = 'PASSWORD'
const env_session_secret = 'SESSION_SECRET'
const env_firebird_url = 'FIREBIRD_URL'
const env_redict_url = 'REDICT_URL'
const env_debug = 'DEBUG'
const env_instance_number = 'INSTANCE_NUMBER'
const env_port = 'PORT'
const env_cache_duration = 'CACHE_DURATION'
const env_session_max_age = 'SESSION_MAX_AGE'
const env_session_name = 'SESSION_NAME'
const env_session_refresh_expire = 'SESSION_REFRESH_EXPIRE'
const env_session_admin_prefix = 'SESSION_ADMIN_PREFIX'

const env_required = [
	env_email,
	env_password,
	env_session_secret,
	env_firebird_url,
	env_redict_url,
]

const env_expected = arrays.append(env_required, [
	env_debug,
	env_instance_number,
	env_port,
	env_cache_duration,
	env_session_max_age,
	env_session_name,
	env_session_refresh_expire,
	env_session_admin_prefix,
])

const env_defaults = {
	env_debug:                  'false'
	env_instance_number:        '0'
	env_port:                   '8080'
	env_cache_duration:         '1800' // 30 minutes
	env_session_max_age:        '86400' // One day
	env_session_name:           'Session'
	env_session_refresh_expire: 'false'
	env_session_admin_prefix:   'Admin'
}

// remove_invalid_settings checks if the settings provided are valid: if the provided settings are invalid,
// and these settings have defaults (added with add_default_settings), they are removed from the environment.
fn remove_invalid_settings() {
	bool_to_be_parsed := [
		'DEBUG',
	]
	for str in bool_to_be_parsed {
		if !can_parse_bool(os.getenv(env_prefix + str)) {
			os.unsetenv(env_prefix + str)
		}
	}
}

// add_default_settings adds any missing setting to the environment.
fn add_default_settings() {
	for key, val in env_defaults {
		os.setenv(env_prefix + key, val, false)
	}
}

// prepare_settings provides the list of expected environment variable keys.
// These keys are expected to be provided with a prefix, this prefix is removed by remove_prefix.
// This list contains all the environment variables used by peony.
fn prepare_settings() {
	verify_settings()
	remove_prefix()
}

// verify_settings verifies all required settings are available in the environment, and panics if any
// is missing.
fn verify_settings() {
	for key in env_required {
		if os.getenv(env_prefix + key) == '' {
			panic(format_error_message('Missing environment variable ${key}'))
		}
	}
}

// remove_prefix removes the prefixed variables from the environment,
// replacing them with unprefixed ones.
fn remove_prefix() {
	for key in env_expected {
		val := os.getenv(env_prefix + key)
		os.unsetenv(env_prefix + key)
		os.setenv(key, val, false)
	}
}

// load_settings reads .env file and loads settings into the environment,
// settings are validated and default settings are set if missing
//
// This function should be called first in the main function
pub fn load_settings() {
	dotenv.load()
	remove_invalid_settings()
	add_default_settings()
	prepare_settings()
}
