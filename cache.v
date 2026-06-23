module peony

import log
import json
import einar_hjortdal.firebird
import internal.conduit

// TODO cache for store endpoints:
// store items in redis after retrieving from db
// intercept conduit calls to get cached items instead if they exist, otherwise cache them
// when data is modified, invalidate cache: how to do that?

// TODO use cached locales -> TODO delete translations from db when disabling a locale
// TODO when updating translations: accept map with locale_code keys, match to id at validation.
// accepting a map makes more sense than accepting an array, as translations have no order.

const api_key_prefix = 'api_key'
const region_prefix = 'region'
const store_locale_prefix = 'store_locale'
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

fn (mut app App) cache_api_key_del(api_key_id ID) ! {
	app.redict.del(build_key(api_key_prefix, api_key_id.string())).error()!
}

fn (mut app App) cache_region_set(region conduit.Region) ! {
	app.redict.set(build_key(region_prefix, region.id.string()), json.encode(region),
		app.config.cache_duration).error()!
}

fn (mut app App) cache_region_get(region_id ID) !conduit.Region {
	encoded := app.redict.get(build_key(region_prefix, region_id.string())).result()!
	return json.decode(conduit.Region, encoded)!
}

fn (mut app App) cache_region_del(region_id ID) ! {
	app.redict.del(build_key(region_prefix, region_id.string())).error()!
}

fn (mut app App) cache_store_locale_set(locale conduit.Locale) ! {
	app.redict.set(build_key(store_locale_prefix, locale.id.string()), json.encode(locale),
		app.config.cache_duration).error()!

	app.redict.set(build_key(store_locale_prefix, locale.code), locale.id.string(),
		app.config.cache_duration).error()!
}

fn (mut app App) cache_store_locale_get(locale_id ID) !conduit.Locale {
	encoded := app.redict.get(build_key(store_locale_prefix, locale_id.string())).result()!
	return json.decode(conduit.Locale, encoded)!
}

fn (mut app App) cache_store_locale_del(locale_id ID) ! {
	locale := app.cache_store_locale_get(locale_id)!

	app.redict.del(build_key(store_locale_prefix, locale_id.string()), build_key(store_locale_prefix,
		locale.code)).error()!
}

fn (mut app App) cache_store_locale_id_get(locale_code string) !conduit.Locale {
	id := app.redict.get(build_key(store_locale_prefix, locale_code)).result()!
	encoded := app.redict.get(build_key(store_locale_prefix, id)).result()!
	return json.decode(conduit.Locale, encoded)!
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

fn (mut app App) cache_set_store(store conduit.Store) {
	log.debug('setting default_locale_id in cache')
	app.cache_default_locale_id_set(store.default_locale_id) or {
		log.debug('failed to set default_locale_id in cache: ${err}')
	}

	log.debug('setting default_region_id in cache')
	app.cache_default_region_id_set(store.default_region_id) or {
		log.debug('failed to set default_region_id in cache: ${err}')
	}

	log.debug('setting default_sales_channel_id in cache')
	app.cache_default_sales_channel_id_set(store.default_sales_channel_id) or {
		log.debug('failed to set default_sales_channel_id in cache: ${err}')
	}

	log.debug('setting store locales in cache')
	for i := 0; i < store.locales.len; i++ {
		locale := store.locales[i]
		app.cache_store_locale_set(locale) or {
			log.debug('failed to set store locale in cache: ${err}')
		}
	}
}

fn (mut app App) get_default_locale_id() !ID {
	default_locale_id := app.cache_default_locale_id_get() or {
		log.debug('default_locale_id not taken from cache: ${err.msg()}')
		store := app.with_rollback(fn (mut tx firebird.ClientTransaction) !conduit.Store {
			return conduit.store_get(mut tx)!
		})!
		app.cache_set_store(store)
		return store.default_locale_id
	}
	return default_locale_id
}

fn (mut app App) get_default_region_id() !ID {
	default_region_id := app.cache_default_region_id_get() or {
		log.debug('default_region_id not taken from cache: ${err.msg()}')
		store := app.with_rollback(fn (mut tx firebird.ClientTransaction) !conduit.Store {
			return conduit.store_get(mut tx)!
		})!
		app.cache_set_store(store)
		return store.default_region_id
	}
	return default_region_id
}
