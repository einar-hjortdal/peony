module conduit

import einar_hjortdal.firebird
import record
import internal.errors

pub fn currency_list(mut tx firebird.ClientTransaction, p CurrencyRetrieveParams) !List[Currency] {
	count := record.currency_retrieve_count(mut tx, p) or {
		return errors.internal('Could not retrieve currency count', err.msg())
	}

	if count == 0 {
		return List[Currency]{}
	}

	currencies := record.currency_retrieve(mut tx, p) or {
		return errors.internal('Could not retrieve currencies from database', err.msg())
	}

	return List[Currency]{
		count: count
		items: currencies
	}
}

pub fn currency_get(mut tx firebird.ClientTransaction, code string) !Currency {
	currencies := record.currency_retrieve(mut tx, CurrencyRetrieveParams{
		codes:  [code]
		offset: offset_default
		fetch:  1
		order:  order_default
	}) or { return errors.internal('Could not retrieve currencies from database', err.msg()) }

	if currencies.len == 0 {
		return errors.internal('currency not found', 'No currency was found with code `${code}`')
	}
	currency := currencies[0]
	return currency
}
