module peony

import einar_hjortdal.firebird

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
