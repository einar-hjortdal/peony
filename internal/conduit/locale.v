module conduit

import einar_hjortdal.firebird
import record
import internal.errors

pub fn locale_list_count(mut tx firebird.ClientTransaction, p LocaleRetrieveParams) !i64 {
	count := record.locale_retrieve_count(mut tx, p) or {
		return errors.internal('Could not retrieve locale count', err.msg())
	}
	return count
}

pub fn locale_list(mut tx firebird.ClientTransaction, p LocaleRetrieveParams) ![]Locale {
	locales := record.locale_retrieve(mut tx, p) or {
		return errors.internal('Could not retrieve locale', err.msg())
	}
	return locales
}

pub fn locale_get_by_id(mut tx firebird.ClientTransaction, locale_id ID) !Locale {
	locales := record.locale_retrieve(mut tx, LocaleRetrieveParams{
		ids:    [locale_id]
		fetch:  1
		offset: offset_default
		order:  order_default
	}) or { return errors.internal('Could not retrieve locale', err.msg()) }

	if locales.len == 0 {
		return errors.not_found('locale not found', 'no locale exists with the given id')
	}

	locale := locales[0]
	return locale
}
