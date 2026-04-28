module conduit

import einar_hjortdal.firebird
import record

pub type SalesChannel = record.SalesChannel

pub fn sales_channel_create(mut tx firebird.Transaction, sales_channel_id ID, p SalesChannelRequest) ! {
	record.sales_channel_create(mut tx, sales_channel_id, p) or {
		return new_error_internal('Could not create sales_channel', err.msg())
	}
}

pub fn sales_channel_update(mut tx firebird.Transaction, sales_channel_id ID, p SalesChannelUpdateRequest) ! {
	record.sales_channel_update(mut tx, sales_channel_id, p) or {
		return new_error_internal('Could not create sales_channel', err.msg())
	}
}

pub type SalesChannelRetrieveParams = record.SalesChannelRetrieveParams

pub fn sales_channel_get(mut tx firebird.Transaction, sales_channel_id ID) !SalesChannel {
	sales_channels := record.sales_channel_retrieve(mut tx, SalesChannelRetrieveParams{
		ids:    [sales_channel_id]
		offset: offset_default
		fetch:  1
		order:  order_default
	}) or { return new_error_internal('Could not retrieve sales channels', err.msg()) }

	if sales_channels.len == 0 {
		return new_error_not_found('sales_channel not found',
			'No sales_channel exists with id `${sales_channel_id.string()}`')
	}

	sales_channel := sales_channels[0]
	return sales_channel
}

pub fn sales_channel_stock_location_add(mut tx firebird.Transaction, sales_channel_id ID, stock_location_id ID) ! {
	record.sales_channel_stock_location_add(mut tx, sales_channel_id, stock_location_id) or {
		return new_error_internal('Could not add stock_location to sales_channel', err.msg())
	}
}

pub fn sales_channel_stock_location_delete(mut tx firebird.Transaction, sales_channel_id ID, stock_location_id ID) ! {
	record.sales_channel_stock_location_delete(mut tx, sales_channel_id, stock_location_id) or {
		tx.rollback() or {}
		return new_error_internal('Could not remove stock_location from sales_channel', err.msg())
	}
}

