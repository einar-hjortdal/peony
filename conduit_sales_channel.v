module peony

import veb

fn conduit_sales_channels_get(mut app App, mut ctx Context, ph ListSalesChannelsParamsHygienised) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	count := model_sales_channel_retrieve_count(mut tx, ph) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve sales channels count', err.msg())
	}

	sales_channels := model_sales_channel_retrieve(mut tx, ph) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve sales channels', err.msg())
	}

	tx.rollback() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }

	mut external_sales_channels := []SalesChannelResponse{len: sales_channels.len}
	for i := 0; i < sales_channels.len; i++ {
		external_sales_channels[i] = format_sales_channel_response(sales_channels[i])
	}

	r := SalesChannelResponseEnvelope{
		sales_channels: external_sales_channels
		count:          count
		offset:         get_offset_amount(ph.offset)
		fetch:          ph.fetch.v
	}
	return ctx.json(r)
}

fn conduit_sales_channel_stock_location_add(mut app App, mut ctx Context, sales_channel_id_bin []u8, stock_location_id_bin []u8) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	model_sales_channel_stock_location_add(mut tx, sales_channel_id_bin, stock_location_id_bin) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not add stock_location to sales_channel',
			err.msg())
	}

	tx.commit() or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, error_transaction_rollback, err.msg())
	}

	return success(mut ctx)
}

fn conduit_sales_channel_stock_location_delete(mut app App, mut ctx Context, sales_channel_id_bin []u8, stock_location_id_bin []u8) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	model_sales_channel_stock_location_delete(mut tx, sales_channel_id_bin, stock_location_id_bin) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not remove stock_location from sales_channel',
			err.msg())
	}

	tx.commit() or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, error_transaction_rollback, err.msg())
	}

	return success(mut ctx)
}
