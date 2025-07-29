module peony

import veb
import net.http

fn conduit_sales_channels_get(mut app App, mut ctx Context, ph ListSalesChannelsParamsHygienised) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error(mut ctx, http.Status.internal_server_error, error_transaction_start,
			err.msg())
	}

	internal_sales_channels, count := app.list_sales_channels(mut tx, ph) or {
		tx.rollback() or {}
		return handle_error(mut ctx, http.Status.internal_server_error, 'Could not retrieve sales channels',
			err.msg())
	}

	tx.rollback() or {
		return handle_error(mut ctx, http.Status.internal_server_error, error_transaction_rollback,
			err.msg())
	}

	mut external_sales_channels := []SalesChannelResponse{len: internal_sales_channels.len}
	for i := 0; i < internal_sales_channels.len; i++ {
		external_sales_channels[i] = format_sales_channel_response(internal_sales_channels[i])
	}

	r := SalesChannelResponseEnvelope{
		sales_channels: external_sales_channels
		count:          count
		offset:         get_offset_amount(ph.offset)
		fetch:          get_fetch_amount(ph.fetch)
	}
	return ctx.json(r)
}

fn conduit_sales_channels_get_by_id(mut app App, mut ctx Context, ids_bin [][]u8) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error(mut ctx, http.Status.internal_server_error, error_transaction_start,
			err.msg())
	}

	sales_channels := do_retrieve_sales_channels_by_ids(mut tx, ids_bin) or {
		return handle_error(mut ctx, http.Status.internal_server_error, 'Could not retrieve sales channel data',
			err.msg())
	}

	tx.rollback() or {
		return handle_error(mut ctx, http.Status.internal_server_error, error_transaction_rollback,
			err.msg())
	}

	return ctx.json(sales_channels)
}
