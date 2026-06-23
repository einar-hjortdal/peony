module peony

import internal.conduit
import json

// TODO cache for store endpoints:
// store items in redis after retrieving from db
// intercept conduit calls to get cached items instead if they exist, otherwise cache them
// when data is modified, invalidate cache: how to do that?

// TODO use cached locales -> TODO delete translations from db when disabling a locale
// TODO when updating translations: accept map with locale_code keys, match to id at validation.
// accepting a map makes more sense than accepting an array, as translations have no order.

const api_key_prefix = 'api_key'
const locales_enabled_set_suffix = 'locales_enabled'
const default_locale_id_key_prefix = 'default_locale_id'
const default_region_id_key_prefix = 'default_region_id'
const default_sales_channel_id_key_prefix = 'default_sales_channel_id'

fn build_key(p ...string) string {
	return '${lib}:${p.join(':')}'
}

fn (mut app App) cache_api_key_set(api_key conduit.APIKey) ! {
	app.redict.set(build_key(api_key_prefix, api_key.id.string()), json.encode(api_key),
		app.config.cache_duration).error()!
}

fn (mut app App) cache_api_key_get(api_key_id ID) !conduit.APIKey {
	encoded := app.redict.get(build_key(api_key_prefix, api_key_id.string())).result()!
	return json.decode(conduit.APIKey, encoded)!
}

fn (mut app App) cache_api_key_delete(api_key_id ID) ! {
	app.redict.del(build_key(api_key_prefix, api_key_id.string())).error()!
}

// stores a hash of locale id to code
fn (mut app App) cache_locales_enabled(locales []conduit.Locale) ! {
	key := build_key(locales_enabled_set_suffix)
	mut pairs := []string{len: 2 * locales.len}
	for i := 0; i < locales.len; i++ {
		pairs[2 * i] = locales[i].id.string()
		pairs[2 * i + 1] = locales[i].code
	}
	app.redict.hset(key, ...pairs).error()!
	app.redict.expire(key, app.config.cache_duration).error()!
}

fn (mut app App) cache_locale_enabled_get(locale_id ID) !string {
	return app.redict.hget(build_key(locales_enabled_set_suffix), locale_id.string()).result()!
}

fn (mut app App) cache_locale_enable(locale conduit.Locale) ! {
	app.redict.hset(build_key(locales_enabled_set_suffix), locale.id.string(), locale.code).error()!
}

fn (mut app App) cache_locale_disable(locale_id ID) ! {
	app.redict.hdel(build_key(locales_enabled_set_suffix), locale_id.string()).error()!
}

fn (mut app App) cache_default_locale_id_set(locale_id ID) ! {
	app.redict.set(build_key(default_locale_id_key_prefix), locale_id.string(),
		app.config.cache_duration).error()!
}

fn (mut app App) cache_default_locale_id_get() !ID {
	id := app.redict.get(build_key(default_locale_id_key_prefix)).result()!
	return id_from_string(id)
}

fn (mut app App) cache_default_region_id_set(region_id ID) ! {
	app.redict.set(build_key(default_region_id_key_prefix), region_id.string(),
		app.config.cache_duration).error()!
}

fn (mut app App) cache_default_region_id_get() !ID {
	id := app.redict.get(build_key(default_region_id_key_prefix)).result()!
	return id_from_string(id)
}

fn (mut app App) cache_default_sales_channel_id_set(sales_channel_id ID) ! {
	app.redict.set(build_key(default_sales_channel_id_key_prefix), sales_channel_id.string(),
		app.config.cache_duration).error()!
}

fn (mut app App) cache_default_sales_channel_id_get() !ID {
	id := app.redict.get(build_key(default_sales_channel_id_key_prefix)).result()!
	return id_from_string(id)
}
