module conduit

import einar_hjortdal.firebird
import record

pub fn currency_list_count(mut tx firebird.Transaction, p CurrencyRetrieveParams) !i64 {
	count := record.currency_retrieve_count(mut tx, p) or {
		return new_error_internal('Could not retrieve currency count', err.msg())
	}
	return count
}

pub fn currency_list(mut tx firebird.Transaction, p CurrencyRetrieveParams) ![]Currency {
	currencies := record.currency_retrieve(mut tx, p) or {
		return new_error_internal('Could not retrieve currencies from database', err.msg())
	}
	return currencies
}

pub fn currency_get(mut tx firebird.Transaction, code string) !Currency {
	currencies := record.currency_retrieve(mut tx, CurrencyRetrieveParams{
		codes:  [code]
		offset: offset_default
		fetch:  1
		order:  order_default
	}) or { return new_error_internal('Could not retrieve currencies from database', err.msg()) }

	if currencies.len == 0 {
		return new_error_internal('currency not found', 'No currency was found with code `${code}`')
	}
	currency := currencies[0]
	return currency
}
