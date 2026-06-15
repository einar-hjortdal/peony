module peony

import json
import time
import internal.conduit

// TODO cache for store endpoints:
// store items in redis after retrieving from db
// intercept conduit calls to get cached items instead if they exist, otherwise cache them
// when data is modified, invalidate cache: how to do that?

// TODO cache for admin endpoints:
// cache locales
// first attempt to read cached locales from redict
// if redict does not have cached locales, read all locales from database, serialize a blob and set it in redict
// this allows:
// when requesting locales, all locales can be sent without db queries
// when updating translations: accept map with locale_code keys, match to id at validation.
// accepting a map makes more sense than accepting an array, as translations have no order.

const one_day = 24 * time.hour
const one_month = 30 * one_day
const api_key_prefix = 'api_key'

fn build_key(p ...string) string {
	return p.join(':')
}

fn get_api_key_key(api_key_id ID) string {
	return build_key(lib, api_key_prefix, api_key_id.string())
}

fn (mut app App) cache_set_api_key(api_key conduit.APIKey) ! {
	api_key_key := get_api_key_key(api_key.id)
	app.redict.set(api_key_key, json.encode(api_key), one_month).error()!
}

fn (mut app App) cache_get_api_key(api_key_id ID) !conduit.APIKey {
	v := app.redict.get(get_api_key_key(api_key_id)).result()!
	api_key := json.decode(conduit.APIKey, v)!
	return api_key
}

fn (mut app App) cache_delete_api_key(api_key_id ID) ! {
	api_key_key := get_api_key_key(api_key_id)
	app.redict.del(api_key_key).error()!
}

// TODO: to prevent dos attacks targeting database operations (garbage api_key header content), cache api keys until invalidation, only check redict not firebird. Populate cache on startup if not populated already, use SADD to keep track of all cached api keys.
fn (mut app App) initiate_cache() ! {
	// build cache
}
