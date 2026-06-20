module conduit

import einar_hjortdal.firebird
import record
import internal.errors

pub fn store_get(mut tx firebird.ClientTransaction) !Store {
	mut store := record.store_retrieve(mut tx) or {
		return errors.internal('Failed to retrieve store', err.msg())
	}

	locales := record.store_locales_retrieve(mut tx) or {
		return errors.internal('Failed to retrieve store locales', err.msg())
	}

	store.locales = locales
	return store
}

pub struct StoreUpdateParams {
pub:
	id                        ID
	name                      ?string
	default_locale_id         ?ID
	default_region_id         ?ID
	default_stock_location_id ?ID
	default_sales_channel_id  ?ID
	locale_ids                ?[]ID
}

fn (p StoreUpdateParams) check(mut _ firebird.ClientTransaction) ! {
	// TODO locale_id exists
	// TODO region_id exists
	// TODO stock_location_id exists
	// TODO sales_channel_id exists
	// TODO locale_ids exist
}

fn (p StoreUpdateParams) parse_locales() ?[]ID {
	locale_ids := p.locale_ids or { return none }
	return locale_ids
}

struct StoreUpdateData {
	store      record.StoreUpdateParams
	locale_ids ?[]ID
}

fn (p StoreUpdateParams) parse() StoreUpdateData {
	store := record.StoreUpdateParams{
		name:                      p.name
		default_locale_id:         p.default_locale_id
		default_region_id:         p.default_region_id
		default_stock_location_id: p.default_stock_location_id
		default_sales_channel_id:  p.default_sales_channel_id
	}

	locale_ids := p.parse_locales()

	return StoreUpdateData{
		store:      store
		locale_ids: locale_ids
	}
}

pub fn store_update(mut tx firebird.ClientTransaction, p StoreUpdateParams) ! {
	p.check(mut tx)!
	data := p.parse()
	record.store_update(mut tx, p.id, data.store) or {
		return errors.internal('Could not update store data', err.msg())
	}

	if locale_ids := data.locale_ids {
		record.store_locales_update(mut tx, p.id, locale_ids) or {
			return errors.internal('Could not update store locales', err.msg())
		}
	}
}

pub fn store_locale_list(mut tx firebird.ClientTransaction) ![]Locale {
	locales := record.store_locales_retrieve(mut tx) or {
		return errors.internal('Could not retrieve store locales', err.msg())
	}
	return locales
}
