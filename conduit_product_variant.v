module main

import net.http
import veb

fn conduit_product_variant_update(mut app App, mut ctx Context, variant_id_bin []u8, p ProductVariantRequest) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error(mut ctx, http.Status.internal_server_error, error_transaction_start,
			err.msg())
	}

	do_update_product_variant(mut tx, variant_id_bin, p) or {
		return handle_error(mut ctx, http.Status.internal_server_error, 'Could not update product_variant',
			err.msg())
	}

	if money_amounts := p.money_amounts {
		do_update_product_variant_money_amount(mut app, mut tx, variant_id_bin, money_amounts) or {
			tx.rollback() or {} // ignore error
			return handle_error(mut ctx, http.Status.internal_server_error, 'Could not update product_variant money_amount',
				err.msg())
		}
	}

	tx.commit() or {
		return handle_error(mut ctx, http.Status.internal_server_error, error_transaction_commit,
			err.msg())
	}

	return success(mut ctx)
}
