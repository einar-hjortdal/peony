module peony

import net.http
import veb

fn conduit_product_variant_update(mut app App, mut ctx Context, variant_id_bin []u8, p ProductVariantRequest, ma []MoneyAmountRequestHygienised) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error(mut ctx, http.Status.internal_server_error, error_transaction_start,
			err.msg())
	}

	if !(p.title == none && p.sku == none && p.ean == none && p.upc == none && p.barcode == none
		&& p.hs_code == none && p.variant_rank == none && p.inventory_quantity == none
		&& p.allow_backorder == none && p.manage_inventory == none && p.origin_country == none
		&& p.mid_code == none && p.weight == none && p.length == none && p.height == none
		&& p.width == none) {
		do_update_product_variant(mut tx, variant_id_bin, p) or {
			return handle_error(mut ctx, http.Status.internal_server_error, 'Could not update product_variant',
				err.msg())
		}
	}

	if ma.len != 0 {
		do_update_product_variant_money_amount(mut app, mut tx, variant_id_bin, ma) or {
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
