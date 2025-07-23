module peony

import veb
import net.http

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
