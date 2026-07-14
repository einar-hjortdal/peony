module conduit

import einar_hjortdal.firebird
import record
import internal.errors
import internal.common
import objects

pub fn stock_location_list(mut tx firebird.ClientTransaction, p StockLocationRetrieveParams) !List[StockLocation] {
	count := record.stock_location_retrieve_count(mut tx, record.StockLocationRetrieveParams{
		ids:          p.ids
		with_deleted: p.with_deleted
		offset:       p.offset
		fetch:        p.fetch
		order:        p.order
	}) or { return errors.internal('Could not get stock_location count', err.msg()) }

	if count == 0 {
		return List[StockLocation]{}
	}

	stock_locations := record.stock_location_retrieve(mut tx, p) or {
		return errors.internal('Could not get stock_location', err.msg())
	}

	if stock_locations.len == 0 {
		return List[StockLocation]{
			count: count
		}
	}

	return List[StockLocation]{
		count: count
		items: stock_locations
	}
}

pub fn stock_location_get(mut tx firebird.ClientTransaction, stock_location_id common.ID) !StockLocation {
	stock_locations := record.stock_location_retrieve(mut tx, record.StockLocationRetrieveParams{
		ids:          [stock_location_id]
		with_deleted: true
		offset:       objects.offset_default
		fetch:        objects.min_fetch
		order:        objects.order_default
	}) or { return errors.internal('Could not get stock_location', err.msg()) }

	if stock_locations.len == 0 {
		return errors.not_found('stock_location not found',
			'No stock_location exists with id `${stock_location_id.string()}`')
	}

	stock_location := stock_locations[0]
	return stock_location
}

pub fn stock_location_create(mut tx firebird.ClientTransaction, p StockLocationCreateParams) ! {
	record.stock_location_create(mut tx, p) or {
		return errors.internal('Could not create stock_location', err.msg())
	}
}

pub struct StockLocationUpdateParams {
pub:
	id   common.ID
	name string
}

fn (p StockLocationUpdateParams) check(mut tx firebird.ClientTransaction) ! {
	count := record.stock_location_retrieve_count(mut tx, record.StockLocationRetrieveParams{
		ids:          [p.id]
		with_deleted: true
		offset:       objects.offset_default
		fetch:        objects.min_fetch
		order:        objects.order_default
	})!

	if count == 0 {
		return errors.not_found('stock_location not found',
			'No stock_location exists with id `${p.id.string()}`')
	}
}

fn (p StockLocationUpdateParams) parse() record.StockLocationUpdateParams {
	return record.StockLocationUpdateParams{
		id:   p.id
		name: p.name
	}
}

pub fn stock_location_update(mut tx firebird.ClientTransaction, p StockLocationUpdateParams) ! {
	p.check(mut tx)!
	data := p.parse()
	record.stock_location_update(mut tx, data) or {
		return errors.internal('Could not create stock_location', err.msg())
	}
}

pub fn stock_location_delete(mut tx firebird.ClientTransaction, stock_location_id common.ID) ! {
	store := record.store_retrieve(mut tx) or {
		return errors.internal('failed to retrieve store', err.msg())
	}

	if stock_location_id.string() == store.default_stock_location_id.string() {
		return errors.unprocessable_entity('Cannot delete default stock location',
			'Update default stock location first')
	}

	stock_locations := record.stock_location_retrieve(mut tx, record.StockLocationRetrieveParams{
		ids:          [stock_location_id]
		with_deleted: false
		offset:       objects.offset_default
		fetch:        objects.min_fetch
		order:        objects.order_default
	}) or { return errors.internal('failed to retrieve stock_locations', err.msg()) }

	if stock_locations.len == 0 {
		return errors.unprocessable_entity('stock_location is already deleted',
			'cannot delete an already-deleted stock_location')
	}

	record.stock_location_delete(mut tx, stock_location_id) or {
		return errors.internal('Could not delete stock_location', err.msg())
	}
}
