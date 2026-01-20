module peony

import veb

fn conduit_seo_delete(mut app App, mut ctx Context, seo_id_bin []u8) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	model_seo_delete(mut tx, seo_id_bin) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not delete seo', err.msg())
	}

	tx.commit() or { return handle_error_500(mut ctx, error_transaction_commit, err.msg()) }

	return success(mut ctx)
}
