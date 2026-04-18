module peony

import json

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

// Distributed FIFO queue for "important" operations (orders, etc)

// TODO high priority
// cache api_keys:
// if cache does not contain api_keys data then get all api keys from database and cache them.
// if cache contains api_keys data then continue
// then create a method to find api key data if it exists, otherwise return an error.
// need functions to call for when new api keys are created (invalidate old, cache new data)

const api_key_prefix = 'api_key'
const api_key_set_key = 'api_keys'

fn redict_build_key(p ...string) string {
	return p.join(':')
}

fn (mut app App) redict_set_api_key(api_key APIKey) ! {
}

fn (mut app App) redict_get_api_key(api_key_id ID) !APIKey {
	r := app.redict.get(redict_build_key(lib, api_key_prefix, api_key_id.string()))!
	v, is_nil := r.val().get_string()!
	if is_nil {
		return error('not found')
	}
	api_key := json.decode(APIKey, v)!
	return api_key
}

fn (mut app App) redict_delete_api_key(api_key_id ID) ! {}

fn (mut app App) redict_clear_api_keys() ! {}

fn (mut app App) initiate_cache() ! {
}

