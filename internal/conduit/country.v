module conduit

import einar_hjortdal.firebird
import record
import internal.errors

pub fn country_list(mut tx firebird.ClientTransaction, p CountryRetrieveParams) !List[Country] {
	count := record.country_retrieve_count(mut tx, p) or {
		return errors.internal('Could not retrieve country count', err.msg())
	}

	if count == 0 {
		return List[Country]{}
	}

	countries := record.country_retrieve(mut tx, p) or {
		return errors.internal('Could not retrieve country', err.msg())
	}

	return List[Country]{
		count: count
		items: countries
	}
}
