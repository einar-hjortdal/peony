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
