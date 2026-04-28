module conduit

import einar_hjortdal.firebird
import record

pub type StockLocation = record.StockLocation

pub type StockLocationRetrieveParams = record.StockLocationRetrieveParams

pub fn stock_location_list(mut tx firebird.Transaction, p StockLocationRetrieveParams) ![]StockLocation {
	stock_locations := record.stock_location_retrieve(mut tx, p) or {
		return new_error_internal('Could not get stock_location', err.msg())
	}
	return stock_locations
}

pub fn stock_location_get(mut tx firebird.Transaction, stock_location_id ID) !StockLocation {
	stock_locations := record.stock_location_retrieve(mut tx, StockLocationRetrieveParams{
		ids: [stock_location_id]
	}) or { return new_error_internal('Could not get stock_location', err.msg()) }

	if stock_locations.len == 0 {
		return new_error_not_found('stock_location not found',
			'No stock_location exists with id `${stock_location_id.string()}`')
	}

	stock_location := stock_locations[0]
	return stock_location
}

