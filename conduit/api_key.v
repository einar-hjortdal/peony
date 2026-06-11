module conduit

import einar_hjortdal.firebird
import record

pub fn api_key_create(mut tx firebird.ClientTransaction, api_key_id ID, name string, sales_channel_id ID) ! {
	record.api_key_create(mut tx, api_key_id, name, sales_channel_id) or {
		return new_error_internal('Could not create api_key', err.msg())
	}
}

pub fn api_key_get(mut tx firebird.ClientTransaction, api_key_id ID) !record.APIKey {
	api_keys := record.api_key_retrieve(mut tx, APIKeyRetrieveParams{
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

pub fn api_key_list_count(mut tx firebird.ClientTransaction, p APIKeyRetrieveParams) !i64 {
	count := record.api_key_retrieve_count(mut tx, p) or {
		return new_error_internal('Could not retrieve api_key', err.msg())
	}
	return count
}

pub fn api_key_list(mut tx firebird.ClientTransaction, p APIKeyRetrieveParams) ![]record.APIKey {
	api_keys := record.api_key_retrieve(mut tx, p) or {
		return new_error_internal('Could not retrieve api_key', err.msg())
	}
	return api_keys
}

pub fn api_key_update(mut tx firebird.ClientTransaction, api_key ID, p APIKeyUpdateParams) ! {
	record.api_key_update(mut tx, api_key, p) or {
		return new_error_internal('Could not update api_key', err.msg())
	}
}

pub fn api_key_delete(mut tx firebird.ClientTransaction, api_key ID) ! {
	record.api_key_delete(mut tx, api_key) or {
		return new_error_internal('Could not delete api_key', err.msg())
	}
}

