module conduit

import einar_hjortdal.firebird
import record

pub fn country_list_count(mut tx firebird.Transaction, p record.CountryRetrieveParams) !i64 {
	count := record.country_retrieve_count(mut tx, p) or {
		return new_error_internal('Could not retrieve country count', err.msg())
	}
	return count
}

pub fn country_list(mut tx firebird.Transaction, p record.CountryRetrieveParams) ![]record.Country {
	countries := record.country_retrieve(mut tx, p) or {
		return new_error_internal('Could not retrieve country', err.msg())
	}
	return countries
}

