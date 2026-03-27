module peony

import veb

fn conduit_sales_channel_create(mut app App, mut ctx Context, p SalesChannelRequest) veb.Result {
	_, sales_channel_id_bin := app.new_id()

	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	model_sales_channel_create(mut tx, sales_channel_id_bin, p) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not create sales_channel', err.msg())
		return ctx.handle_error(perr)
	}

	tx.commit() or {
		tx.rollback() or {}
		perr := new_error_internal(error_transaction_commit, err.msg())
		return ctx.handle_error(perr)
	}

	return success(mut ctx)
}

fn conduit_sales_channel_update(mut app App, mut ctx Context, sales_channel_id_bin []u8, p SalesChannelUpdateRequest) veb.Result {
	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	model_sales_channel_update(mut tx, sales_channel_id_bin, p) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not create sales_channel', err.msg())
		return ctx.handle_error(perr)
	}

	tx.commit() or {
		tx.rollback() or {}
		perr := new_error_internal(error_transaction_rollback, err.msg())
		return ctx.handle_error(perr)
	}

	return success(mut ctx)
}

fn conduit_sales_channels_get(mut app App, mut ctx Context, p SalesChannelRetrieveParams) veb.Result {
	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	count := model_sales_channel_retrieve_count(mut tx, p) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not retrieve sales channels count', err.msg())
		return ctx.handle_error(perr)
	}

	if count == 0 {
		return ctx.json(SalesChannelResponseEnvelope{
			offset: p.offset
			fetch:  p.fetch
		})
	}

	sales_channels := model_sales_channel_retrieve(mut tx, p) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not retrieve sales channels', err.msg())
		return ctx.handle_error(perr)
	}

	tx.rollback() or {
		perr := new_error_internal(error_transaction_rollback, err.msg())
		return ctx.handle_error(perr)
	}

	mut external_sales_channels := []SalesChannelResponse{len: sales_channels.len}
	for i := 0; i < sales_channels.len; i++ {
		external_sales_channels[i] = format_sales_channel_response(sales_channels[i])
	}

	return ctx.json(SalesChannelResponseEnvelope{
		sales_channels: external_sales_channels
		count:          count
		offset:         p.offset
		fetch:          p.fetch
	})
}

fn conduit_sales_channel_stock_location_add(mut app App, mut ctx Context, sales_channel_id_bin []u8, stock_location_id_bin []u8) veb.Result {
	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	model_sales_channel_stock_location_add(mut tx, sales_channel_id_bin, stock_location_id_bin) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not add stock_location to sales_channel', err.msg())
		return ctx.handle_error(perr)
	}

	tx.commit() or {
		tx.rollback() or {}
		perr := new_error_internal(error_transaction_rollback, err.msg())
		return ctx.handle_error(perr)
	}

	return success(mut ctx)
}

fn conduit_sales_channel_stock_location_delete(mut app App, mut ctx Context, sales_channel_id_bin []u8, stock_location_id_bin []u8) veb.Result {
	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	model_sales_channel_stock_location_delete(mut tx, sales_channel_id_bin, stock_location_id_bin) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not remove stock_location from sales_channel',
			err.msg())
		return ctx.handle_error(perr)
	}

	tx.commit() or {
		tx.rollback() or {}
		perr := new_error_internal(error_transaction_rollback, err.msg())
		return ctx.handle_error(perr)
	}

	return success(mut ctx)
}

