module peony

import log
import veb
import einar_hjortdal.firebird
import internal.conduit
import internal.errors

// list api keys
@['/admin/api-keys'; get]
pub fn (mut app App) api_keys_list(mut ctx Context) veb.Result {
	p := hygienise_api_key_list_query_params(ctx.query) or { return ctx.handle_error(err) }

	data := app.with_rollback(fn [p] (mut tx firebird.ClientTransaction) !ListReturn {
		count := conduit.api_key_list_count(mut tx, p)!
		if count == 0 {
			return ListReturn{}
		}

		api_keys := conduit.api_key_list(mut tx, p)!
		return ListReturn{
			count: count
			items: api_keys
		}
	}) or { return ctx.handle_error(err) }

	mut external_api_keys := []APIKeyResponse{len: data.items.len}
	for i := 0; i < data.items.len; i++ {
		api_key := data.items[i]
		external_api_keys[i] = format_api_key_response(api_key)
	}

	return ctx.handle_ok(APIKeyResponseListEnvelope{
		api_keys: external_api_keys
		count:    data.count
		offset:   p.offset
		fetch:    p.fetch
	})
}

// create api key
@['/admin/api-keys'; post]
pub fn (mut app App) api_keys_create(mut ctx Context) veb.Result {
	api_key_id := app.gen_id()
	p := hygienise_api_key_create_request(ctx.req.data, api_key_id) or {
		return ctx.handle_error(err)
	}

	api_key := app.with_commit(fn [p] (mut tx firebird.ClientTransaction) !conduit.APIKey {
		// TODO verify ph.sales_channel_id exists
		conduit.api_key_create(mut tx, p)!
		return conduit.api_key_get(mut tx, p.id)
	}) or { return ctx.handle_error(err) }

	return ctx.handle_created(APIKeyResponseEnvelope{
		api_key: format_api_key_response(api_key)
	})
}

// get api keys
@['/admin/api-keys/:api_key_id'; get]
pub fn (mut app App) api_keys_get(mut ctx Context, api_key_id string) veb.Result {
	parsed_api_key_id := id_from_string(api_key_id) or {
		return ctx.handle_error(errors.unprocessable_entity(error_id_invalid, 'api_key_id'))
	}

	api_key := app.with_rollback(fn [parsed_api_key_id] (mut tx firebird.ClientTransaction) !conduit.APIKey {
		return conduit.api_key_get(mut tx, parsed_api_key_id)
	}) or { return ctx.handle_error(err) }

	return ctx.handle_ok(APIKeyResponseEnvelope{
		api_key: format_api_key_response(api_key)
	})
}

// update api key (and update cache)
@['/admin/api-keys/:api_key_id'; post]
pub fn (mut app App) api_keys_update(mut ctx Context, api_key_id string) veb.Result {
	parsed_api_key_id := id_from_string(api_key_id) or {
		return ctx.handle_error(errors.unprocessable_entity(error_id_invalid, 'api_key_id'))
	}

	p := hygienise_api_key_update_request(ctx.req.data, parsed_api_key_id) or {
		return ctx.handle_error(err)
	}

	api_key := app.with_commit(fn [p] (mut tx firebird.ClientTransaction) !conduit.APIKey {
		conduit.api_key_update(mut tx, p)!
		return conduit.api_key_get(mut tx, p.id)
	}) or { return ctx.handle_error(err) }

	app.cache_set_api_key(api_key) or {
		log.warn('api_keys_update failed to cache API key: ${err.msg()}')
	}

	return ctx.handle_ok(APIKeyResponseEnvelope{
		api_key: format_api_key_response(api_key)
	})
}

// delete api key (and invalidate cache)
@['/admin/api-keys/:api_key_id'; delete]
pub fn (mut app App) api_keys_delete(mut ctx Context, api_key_id string) veb.Result {
	parsed_api_key_id := id_from_string(api_key_id) or {
		return ctx.handle_error(errors.unprocessable_entity(error_id_invalid, 'api_key_id'))
	}

	app.with_commit(fn [parsed_api_key_id] (mut tx firebird.ClientTransaction) !NilReturn {
		conduit.api_key_delete(mut tx, parsed_api_key_id)!
		return NilReturn{}
	}) or { return ctx.handle_error(err) }

	app.cache_delete_api_key(parsed_api_key_id) or {
		log.warn('api_keys_delete failed to remove API key from cache: ${err.msg()}')
	}

	return ctx.handle_deleted()
}
