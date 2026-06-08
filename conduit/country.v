module conduit

import einar_hjortdal.firebird
import record

pub type Country = record.Country

pub type CountryRetrieveParams = record.CountryRetrieveParams

pub fn country_list_count(mut tx firebird.Transaction, p CountryRetrieveParams) !i64 {
	count := record.country_retrieve_count(mut tx, p) or {
		return new_error_internal('Could not retrieve country count', err.msg())
	}
	return count
}

pub fn country_list(mut tx firebird.Transaction, p CountryRetrieveParams) ![]Country {
	countries := record.country_retrieve(mut tx, p) or {
		return new_error_internal('Could not retrieve country', err.msg())
	}
	return countries
}
