module peony

import einar_hjortdal.firebird

fn conduit_api_key_create(mut tx firebird.Transaction, api_key_id ID, name string, sales_channel_id ID) ! {
	model_api_key_create(mut tx, api_key_id, name, sales_channel_id) or {
		return new_error_internal('Could not create api_key', err.msg())
	}
}

fn conduit_api_key_get(mut tx firebird.Transaction, api_key_id ID) !APIKey {
	api_keys := model_api_key_retrieve(mut tx, APIKeyRetrieveParams{
		ids:    [api_key_id]
		offset: 0
		fetch:  1
		order:  order_default
	}) or { return new_error_internal('Could not retrieve api_key', err.msg()) }

	if api_keys.len == 0 {
		return new_error_not_found('api_key not found', 'api_keys.len == 0')
	}

	return api_keys[0]
}

fn conduit_api_key_list_count(mut tx firebird.Transaction, p APIKeyRetrieveParams) !i64 {
	count := model_api_key_retrieve_count(mut tx, p) or {
		return new_error_internal('Could not retrieve api_key', err.msg())
	}
	return count
}

fn conduit_api_key_list(mut tx firebird.Transaction, p APIKeyRetrieveParams) ![]APIKey {
	api_keys := model_api_key_retrieve(mut tx, p) or {
		return new_error_internal('Could not retrieve api_key', err.msg())
	}
	return api_keys
}

fn conduit_api_key_update(mut tx firebird.Transaction, api_key ID, p APIKeyUpdateParams) ! {
	model_api_key_update(mut tx, api_key, p) or {
		return new_error_internal('Could not update api_key', err.msg())
	}
}

fn conduit_api_key_delete(mut tx firebird.Transaction, api_key ID) ! {
	model_api_key_delete(mut tx, api_key) or {
		return new_error_internal('Could not delete api_key', err.msg())
	}
}

