module conduit

import einar_hjortdal.firebird
import record
import internal.errors

pub fn sales_channel_create(mut tx firebird.ClientTransaction, sales_channel_id ID, p record.SalesChannelCreateParams) ! {
	record.sales_channel_create(mut tx, sales_channel_id, p) or {
		return errors.internal('Could not create sales_channel', err.msg())
	}
}

pub fn sales_channel_update(mut tx firebird.ClientTransaction, sales_channel_id ID, p record.SalesChannelUpdateParams) ! {
	record.sales_channel_update(mut tx, sales_channel_id, p) or {
		return errors.internal('Could not create sales_channel', err.msg())
	}
}

pub fn sales_channel_get(mut tx firebird.ClientTransaction, sales_channel_id ID) !record.SalesChannel {
	sales_channels := record.sales_channel_retrieve(mut tx, SalesChannelRetrieveParams{
		ids:    [sales_channel_id]
		offset: offset_default
		fetch:  1
		order:  order_default
	}) or { return errors.internal('Could not retrieve sales channels', err.msg()) }

	if sales_channels.len == 0 {
		return errors.not_found('sales_channel not found',
			'No sales_channel exists with id `${sales_channel_id.string()}`')
	}

	sales_channel := sales_channels[0]
	return sales_channel
}

pub fn sales_channel_stock_location_add(mut tx firebird.ClientTransaction, sales_channel_id ID, stock_location_id ID) ! {
	record.sales_channel_stock_location_add(mut tx, sales_channel_id, stock_location_id) or {
		return errors.internal('Could not add stock_location to sales_channel', err.msg())
	}
}

pub fn sales_channel_stock_location_delete(mut tx firebird.ClientTransaction, sales_channel_id ID, stock_location_id ID) ! {
	record.sales_channel_stock_location_delete(mut tx, sales_channel_id, stock_location_id) or {
		tx.rollback() or {}
		return errors.internal('Could not remove stock_location from sales_channel', err.msg())
	}
}
