module conduit

import einar_hjortdal.firebird
import record

pub type Locale = record.Locale

pub fn locale_list_count(mut tx firebird.Transaction, p record.LocaleRetrieveParams) !i64 {
	count := record.locale_retrieve_count(mut tx, p) or {
		return new_error_internal('Could not retrieve locale count', err.msg())
	}
	return count
}

pub fn locale_list(mut tx firebird.Transaction, p record.LocaleRetrieveParams) ![]Locale {
	locales := record.locale_retrieve(mut tx, p) or {
		return new_error_internal('Could not retrieve locale', err.msg())
	}
	return locales
}

fn conduit_locale_get(mut tx firebird.Transaction, locale_id ID) !Locale {
	locales := record.locale_retrieve(mut tx, record.LocaleRetrieveParams{
		ids:    [locale_id]
		fetch:  1
		offset: offset_default
		order:  order_default
	}) or { return new_error_internal('Could not retrieve locale', err.msg()) }

	if locales.len == 0 {
		return new_error_not_found('locale not found', 'no locale exists with the given id')
	}

	locale := locales[0]
	return locale
}
