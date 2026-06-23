module conduit

import einar_hjortdal.firebird
import record
import internal.errors

pub struct APIKeyCreateParams {
pub:
	id               ID
	name             string
	sales_channel_id ID
}

fn (p APIKeyCreateParams) check(mut _ firebird.ClientTransaction) ! {
	// does sales_channel_id exist
}

fn (p APIKeyCreateParams) parse() record.APIKeyCreateParams {
	return record.APIKeyCreateParams{
		id:               p.id
		name:             p.name
		sales_channel_id: p.sales_channel_id
	}
}

pub fn api_key_create(mut tx firebird.ClientTransaction, p APIKeyCreateParams) ! {
	p.check(mut tx)!
	data := p.parse()
	record.api_key_create(mut tx, data) or {
		return errors.internal('Could not create api_key', err.msg())
	}
}

pub fn api_key_get(mut tx firebird.ClientTransaction, api_key_id ID) !APIKey {
	api_keys := record.api_key_retrieve(mut tx, APIKeyRetrieveParams{
		ids:    [api_key_id]
		offset: 0
		fetch:  1
		order:  order_default
	}) or { return errors.internal('Could not retrieve api_key', err.msg()) }

	if api_keys.len == 0 {
		return errors.not_found('api_key not found', 'api_keys.len == 0')
	}

	return api_keys[0]
}

pub fn api_key_list_count(mut tx firebird.ClientTransaction, p APIKeyRetrieveParams) !i64 {
	count := record.api_key_retrieve_count(mut tx, p) or {
		return errors.internal('Could not retrieve api_key', err.msg())
	}
	return count
}

pub fn api_key_list(mut tx firebird.ClientTransaction, p APIKeyRetrieveParams) ![]APIKey {
	api_keys := record.api_key_retrieve(mut tx, p) or {
		return errors.internal('Could not retrieve api_key', err.msg())
	}
	return api_keys
}

pub struct APIKeyUpdateParams {
pub:
	id               ID
	name             ?string
	sales_channel_id ?ID
}

fn (p APIKeyUpdateParams) check() ! {
	// does id exist
	// does sales_channel_id exist
}

fn (p APIKeyUpdateParams) parse() record.APIKeyUpdateParams {
	return record.APIKeyUpdateParams{
		id:               p.id
		name:             p.name
		sales_channel_id: p.sales_channel_id
	}
}

pub fn api_key_update(mut tx firebird.ClientTransaction, p APIKeyUpdateParams) ! {
	p.check()!
	data := p.parse()
	record.api_key_update(mut tx, data) or {
		return errors.internal('Could not update api_key', err.msg())
	}
}

pub fn api_key_delete(mut tx firebird.ClientTransaction, api_key ID) ! {
	record.api_key_delete(mut tx, api_key) or {
		return errors.internal('Could not delete api_key', err.msg())
	}
}
