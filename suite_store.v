module peony

import einar_hjortdal.firebird

struct SuiteStoreData {
	locales    []Locale
	currencies []Currency
}

fn suite_store_data_get(mut tx firebird.Transaction) !SuiteStoreData {
	locales := model_store_locales_retrieve(mut tx)!
	currencies := model_store_currencies_retrieve(mut tx)!
	return SuiteStoreData{
		locales:    locales
		currencies: currencies
	}
}
