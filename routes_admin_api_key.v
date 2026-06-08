module peony

import veb
import json
import conduit

// list api keys
@['/admin/api-keys'; get]
pub fn (mut app App) api_keys_list(mut ctx Context) veb.Result {
	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	p := hygienise_api_key_list_query_params(ctx.query) or { return ctx.handle_error(err) }

	count := conduit.api_key_list_count(mut tx, p) or {
		tx.rollback() or {}
		return ctx.handle_error(err)
	}

	api_keys := conduit.api_key_list(mut tx, p) or {
		tx.rollback() or {}
		return ctx.handle_error(err)
	}

	tx.rollback() or {}

	mut external_api_keys := []APIKeyResponse{len: api_keys.len}
	for i := 0; i < api_keys.len; i++ {
		api_key := api_keys[i]
		external_api_keys[i] = format_api_key_response(api_key)
	}

	return ctx.handle_ok(APIKeyListResponseEnvelope{
		api_keys: external_api_keys
		count:    count
		offset:   p.offset
		fetch:    p.fetch
	})
}

// create api key
@['/admin/api-keys'; post]
pub fn (mut app App) api_keys_create(mut ctx Context) veb.Result {
	p := json.decode(APIKeyCreateRequest, ctx.req.data) or {
		perr := new_error_bad_request('Could not decode APIKeyCreateRequest', err.msg())
		return ctx.handle_error(perr)
	}
	ph := hygienise_api_key_create_request(p) or { return ctx.handle_error(err) }

	api_key_id := app.gen_id()

	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	// verify ph.sales_channel_id exists

	conduit.api_key_create(mut tx, api_key_id, ph.name, ph.sales_channel_id) or {
		tx.rollback() or {}
		return ctx.handle_error(err)
	}

	api_key := conduit.api_key_get(mut tx, api_key_id) or {
		tx.rollback() or {}
		return ctx.handle_error(err)
	}

	tx.commit() or {
		perr := new_error_internal(error_transaction_commit, err.msg())
		return ctx.handle_error(perr)
	}

	return ctx.handle_ok(APIKeyResponseEnvelope{
		api_key: format_api_key_response(api_key)
	})
}

// get api keys
@['/admin/api-keys/:api_key_id'; get]
pub fn (mut app App) api_keys_get(mut ctx Context, api_key_id string) veb.Result {
	parsed_api_key_id := id_from_string(api_key_id) or {
		return ctx.handle_error(new_error_unprocessable_entity(error_id_invalid, 'api_key_id'))
	}

	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	api_key := conduit.api_key_get(mut tx, parsed_api_key_id) or {
		tx.rollback() or {}
		return ctx.handle_error(err)
	}

	tx.rollback() or {}

	return ctx.handle_ok(APIKeyResponseEnvelope{
		api_key: format_api_key_response(api_key)
	})
}

// update api key (and update cache)
@['/admin/api-keys/:api_key_id'; post]
pub fn (mut app App) api_keys_update(mut ctx Context, api_key_id string) veb.Result {
	parsed_api_key_id := id_from_string(api_key_id) or {
		perr := new_error_unprocessable_entity(error_id_invalid, 'api_key_id')
		return ctx.handle_error(perr)
	}

	p := json.decode(APIKeyUpdateRequest, ctx.req.data) or {
		perr := new_error_bad_request('Could not decode APIKeyUpdateRequest', err.msg())
		return ctx.handle_error(perr)
	}
	ph := hygienise_api_key_update_request(p) or { return ctx.handle_error(err) }

	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	conduit.api_key_update(mut tx, parsed_api_key_id, APIKeyUpdateParams{
		name:             ph.name
		sales_channel_id: ph.sales_channel_id
	}) or {
		tx.rollback() or {}
		return ctx.handle_error(err)
	}

	api_key := conduit.api_key_get(mut tx, parsed_api_key_id) or {
		tx.rollback() or {}
		return ctx.handle_error(err)
	}

	tx.commit() or {
		perr := new_error_internal(error_transaction_commit, err.msg())
		return ctx.handle_error(perr)
	}

	app.cache_set_api_key(api_key) or {} // TODO handle error

	return ctx.handle_ok(APIKeyResponseEnvelope{
		api_key: format_api_key_response(api_key)
	})
}

// delete api key (and invalidate cache)
@['/admin/api-keys/:api_key_id'; delete]
pub fn (mut app App) api_keys_delete(mut ctx Context, api_key_id string) veb.Result {
	parsed_api_key_id := id_from_string(api_key_id) or {
		perr := new_error_unprocessable_entity(error_id_invalid, 'api_key_id')
		return ctx.handle_error(perr)
	}

	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	conduit.api_key_delete(mut tx, parsed_api_key_id) or {
		tx.rollback() or {}
		return ctx.handle_error(err)
	}

	app.cache_delete_api_key(parsed_api_key_id) or {} // TODO handle error

	tx.commit() or {
		perr := new_error_internal(error_transaction_commit, err.msg())
		return ctx.handle_error(perr)
	}

	return ctx.handle_deleted()
}
