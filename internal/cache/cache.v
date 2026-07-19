module cache

import log
import json2
import time
import einar_hjortdal.redict
import internal.conduit
import internal.common

// TODO cache for store endpoints:
// store items in redis after retrieving from db
// intercept conduit calls to get cached items instead if they exist, otherwise cache them
// when data is modified, invalidate cache

// TODO use cached locales -> TODO delete translations from db when disabling a locale
// TODO when updating translations: accept map with locale_code keys, match to id at validation.

const api_key_prefix = 'api_key'
const region_prefix = 'region'
const store_locale_prefix = 'store_locale'
const default_locale_id_key_prefix = 'default_locale_id'
const default_region_id_key_prefix = 'default_region_id'
const default_sales_channel_id_key_prefix = 'default_sales_channel_id'

fn build_key(p ...string) string {
	return '${common.lib}:${p.join(':')}'
}

pub fn api_key_set(mut rc redict.Client, api_key conduit.APIKey, duration time.Duration) ! {
	rc.set(build_key(api_key_prefix, api_key.id.string()), json2.encode(api_key,
		escape_unicode: true
	), duration).error()!
}

pub fn api_key_get(mut rc redict.Client, api_key_id common.ID) !conduit.APIKey {
	encoded := rc.get(build_key(api_key_prefix, api_key_id.string())).result()!
	return json2.decode[conduit.APIKey](encoded)!
}

pub fn api_key_del(mut rc redict.Client, api_key_id common.ID) ! {
	rc.del(build_key(api_key_prefix, api_key_id.string())).error()!
}

pub fn region_set(mut rc redict.Client, region conduit.Region, duration time.Duration) ! {
	rc.set(build_key(region_prefix, region.id.string()),
		json2.encode(region, escape_unicode: true), duration).error()!
}

pub fn region_get(mut rc redict.Client, region_id common.ID) !conduit.Region {
	encoded := rc.get(build_key(region_prefix, region_id.string())).result()!
	return json2.decode[conduit.Region](encoded)!
}

pub fn region_del(mut rc redict.Client, region_id common.ID) ! {
	rc.del(build_key(region_prefix, region_id.string())).error()!
}

pub fn store_locale_set(mut rc redict.Client, locale conduit.Locale, duration time.Duration) ! {
	rc.set(build_key(store_locale_prefix, locale.id.string()), json2.encode(locale,
		escape_unicode: true
	), duration).error()!

	rc.set(build_key(store_locale_prefix, locale.code), locale.id.string(), duration).error()!
}

pub fn store_locale_get(mut rc redict.Client, locale_id common.ID) !conduit.Locale {
	encoded := rc.get(build_key(store_locale_prefix, locale_id.string())).result()!
	return json2.decode[conduit.Locale](encoded)!
}

pub fn store_locale_del(mut rc redict.Client, locale_id common.ID, duration time.Duration) ! {
	locale := store_locale_get(mut rc, locale_id)!

	rc.del(build_key(store_locale_prefix, locale_id.string()), build_key(store_locale_prefix,
		locale.code)).error()!
}

pub fn store_locale_id_get(mut rc redict.Client, locale_code string) !conduit.Locale {
	id := rc.get(build_key(store_locale_prefix, locale_code)).result()!
	encoded := rc.get(build_key(store_locale_prefix, id)).result()!
	return json2.decode[conduit.Locale](encoded)!
}

pub fn default_locale_id_set(mut rc redict.Client, locale_id common.ID, duration time.Duration) ! {
	rc.set(build_key(default_locale_id_key_prefix), locale_id.string(), duration).error()!
}

pub fn default_locale_id_get(mut rc redict.Client) !common.ID {
	id := rc.get(build_key(default_locale_id_key_prefix)).result()!
	return common.id_from_string(id)
}

pub fn default_region_id_set(mut rc redict.Client, region_id common.ID, duration time.Duration) ! {
	rc.set(build_key(default_region_id_key_prefix), region_id.string(), duration).error()!
}

pub fn default_region_id_get(mut rc redict.Client) !common.ID {
	id := rc.get(build_key(default_region_id_key_prefix)).result()!
	return common.id_from_string(id)
}

pub fn default_sales_channel_id_set(mut rc redict.Client, sales_channel_id common.ID, duration time.Duration) ! {
	rc.set(build_key(default_sales_channel_id_key_prefix), sales_channel_id.string(), duration).error()!
}

pub fn default_sales_channel_id_get(mut rc redict.Client) !common.ID {
	id := rc.get(build_key(default_sales_channel_id_key_prefix)).result()!
	return common.id_from_string(id)
}

pub fn set_store(mut rc redict.Client, store conduit.Store, duration time.Duration) {
	log.debug('setting default_locale_id in cache')
	default_locale_id_set(mut rc, store.default_locale_id, duration) or {
		log.debug('failed to set default_locale_id in cache: ${err}')
	}

	log.debug('setting default_region_id in cache')
	default_region_id_set(mut rc, store.default_region_id, duration) or {
		log.debug('failed to set default_region_id in cache: ${err}')
	}

	log.debug('setting default_sales_channel_id in cache')
	default_sales_channel_id_set(mut rc, store.default_sales_channel_id, duration) or {
		log.debug('failed to set default_sales_channel_id in cache: ${err}')
	}

	log.debug('setting store locales in cache')
	for i := 0; i < store.locales.len; i++ {
		locale := store.locales[i]
		store_locale_set(mut rc, locale, duration) or {
			log.debug('failed to set store locale in cache: ${err}')
		}
	}
}
