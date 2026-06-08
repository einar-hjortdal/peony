module peony

import time

pub const default_port = 8080
pub const default_cache_duration = time.minute * 30
pub const default_session_max_age = time.hour * 24
pub const default_session_name = 'Session'
pub const default_session_admin_prefix = 'Admin'

pub struct Config {
pub:
	default_user_email     string
	default_user_password  string
	session_secret         string
	firebird_url           string
	redict_url             string
	debug                  bool
	port                   u16
	cache_duration         time.Duration
	session_max_age        time.Duration
	session_refresh_expire bool
	session_name           string
	session_admin_prefix   string
}

fn (c Config) get_default_user_email() !string {
	if c.default_user_email == '' {
		return error('default_user_email is required')
	}
	email_is_valid(c.default_user_email) or { return error('invalid email: ${err.msg()}') }
	return c.default_user_email
}

// TODO reject simple passwords
fn (c Config) get_default_user_password() !string {
	if c.default_user_password == '' {
		return error('default_user_password is required')
	}
	return c.default_user_password
}

// TODO reject simple secrets
fn (c Config) get_session_secret() !string {
	if c.session_secret == '' {
		return error('session_secret is required')
	}
	return c.session_secret
}

fn (c Config) get_firebird_url() !string {
	if c.firebird_url == '' {
		return error('firebird_url is required')
	}
	return c.firebird_url
}

fn (c Config) get_redict_url() !string {
	if c.redict_url == '' {
		return error('redict_url is required')
	}
	return c.redict_url
}

fn (c Config) get_port() !u16 {
	if c.port == 0 {
		return default_port
	}
	return c.port
}

fn (c Config) get_cache_duration() time.Duration {
	if c.cache_duration == 0 {
		return default_cache_duration
	}
	return c.cache_duration
}

fn (c Config) get_session_max_age() time.Duration {
	if c.session_max_age == 0 {
		return default_session_max_age
	}
	return c.session_max_age
}

// TODO sanitize
fn (c Config) get_session_name() !string {
	if c.session_name == '' {
		return default_session_name
	}
	return c.session_name
}

// TODO sanitize
fn (c Config) get_session_admin_prefix() !string {
	if c.session_admin_prefix == '' {
		return default_session_admin_prefix
	}
	return c.session_admin_prefix
}

fn (c Config) verify() !Config {
	return Config{
		default_user_email:     c.get_default_user_email()!
		default_user_password:  c.get_default_user_password()!
		session_secret:         c.get_session_secret()!
		firebird_url:           c.get_firebird_url()!
		redict_url:             c.get_redict_url()!
		debug:                  c.debug
		port:                   c.get_port()!
		cache_duration:         c.get_cache_duration()
		session_max_age:        c.get_session_max_age()
		session_refresh_expire: c.session_refresh_expire
		session_name:           c.get_session_name()!
		session_admin_prefix:   c.get_session_admin_prefix()!
	}
}

