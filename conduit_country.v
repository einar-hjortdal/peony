module peony

import einar_hjortdal.firebird

fn conduit_country_list(mut app App, mut tx firebird.Transaction, p CountryRetrieveParams) ![]Country {
	countries := model_country_retrieve(mut tx, p) or {
		return new_error_internal('Could not retrieve countries', err.msg())
	}

	return countries
}

