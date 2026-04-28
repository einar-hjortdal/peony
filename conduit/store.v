module conduit

import einar_hjortdal.firebird
import record

pub type Store = record.Store

pub fn store_get(mut tx firebird.Transaction) !Store {
	mut store := record.store_retrieve(mut tx) or {
		return new_error_internal('Failed to retrieve store', err.msg())
	}

	locales := record.store_locales_retrieve(mut tx) or {
		return new_error_internal('Failed to retrieve store locales', err.msg())
	}

	store.locales = locales
	return store
}

pub type StoreUpdateParams = record.StoreUpdateParams

fn conduit_store_update(mut tx firebird.Transaction, store_id ID, p StoreUpdateParams) ! {
	if p.name != none || p.default_locale_id != none || p.default_region_id != none
		|| p.default_stock_location_id != none || p.default_sales_channel_id != none {
		record.store_update(mut tx, store_id, p) or {
			return new_error_internal('Could not update store data', err.msg())
		}
	}

	if locale_ids := p.locale_ids {
		record.store_locales_update(mut tx, store_id, locale_ids) or {
			return new_error_internal('Could not update store locales', err.msg())
		}
	}
}

