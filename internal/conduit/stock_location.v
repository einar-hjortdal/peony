module conduit

import einar_hjortdal.firebird
import record
import internal.errors

pub struct StockLocationRetrieveParams {
pub:
	ids          ?[]ID
	with_deleted bool
	offset       i32
	fetch        i32
	order        string
}

// TODO
fn (p StockLocationRetrieveParams) check(mut _ firebird.ClientTransaction) ! {
}

fn (p StockLocationRetrieveParams) parse() record.StockLocationRetrieveParams {
	return record.StockLocationRetrieveParams{
		ids:          p.ids
		with_deleted: p.with_deleted
		offset:       p.offset
		fetch:        p.fetch
		order:        p.order
	}
}

pub fn stock_location_list(mut tx firebird.ClientTransaction, p StockLocationRetrieveParams) ![]StockLocation {
	data := p.parse()
	stock_locations := record.stock_location_retrieve(mut tx, data) or {
		return errors.internal('Could not get stock_location', err.msg())
	}
	return stock_locations
}

pub fn stock_location_get(mut tx firebird.ClientTransaction, stock_location_id ID) !StockLocation {
	stock_locations := record.stock_location_retrieve(mut tx, record.StockLocationRetrieveParams{
		ids: [stock_location_id]
	}) or { return errors.internal('Could not get stock_location', err.msg()) }

	if stock_locations.len == 0 {
		return errors.not_found('stock_location not found',
			'No stock_location exists with id `${stock_location_id.string()}`')
	}

	stock_location := stock_locations[0]
	return stock_location
}
