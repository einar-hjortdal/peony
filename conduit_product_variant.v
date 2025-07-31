module peony

import net.http
import veb

fn conduit_product_variants_get(mut app App, mut ctx Context, ph RetrieveProductVariantParamsHygienised) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error(mut ctx, http.Status.internal_server_error, error_transaction_start,
			err.msg())
	}

	variants, count := model_retrieve_product_variants(mut tx, ph) or {
		tx.rollback() or {}
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Could not retrieve variants ', err.msg()))
	}

	tx.rollback() or {
		return handle_error(mut ctx, http.Status.internal_server_error, error_transaction_rollback,
			err.msg())
	}

	r := VariantResponseListEnvelope{
		variants: variants
		count:    count
		offset:   get_offset_amount(ph.offset)
		fetch:    get_fetch_amount(ph.fetch)
	}

	return ctx.json(r)
}

fn conduit_product_variant_get(mut app App, mut ctx Context, ph RetrieveProductVariantParamsHygienised) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error(mut ctx, http.Status.internal_server_error, error_transaction_start,
			err.msg())
	}

	variants, count := model_retrieve_product_variants(mut tx, ph) or {
		tx.rollback() or {}
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Could not retrieve variants ', err.msg()))
	}

	tx.rollback() or {
		return handle_error(mut ctx, http.Status.internal_server_error, error_transaction_rollback,
			err.msg())
	}

	if count == 0 {
		return handle_error(mut ctx, http.Status.not_found, 'No variant exists with the given id',
			'count == 0')
	}

	r := VariantResponseEnvelope{
		variant: variants[0]
	}

	return ctx.json(r)
}

fn conduit_product_variant_update(mut app App, mut ctx Context, variant_id_bin []u8, p ProductVariantRequest, ma []MoneyAmountRequestHygienised) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error(mut ctx, http.Status.internal_server_error, error_transaction_start,
			err.msg())
	}

	if p.title != none || p.sku != none || p.ean != none || p.upc != none || p.barcode != none
		|| p.hs_code != none || p.variant_rank != none || p.inventory_quantity != none
		|| p.allow_backorder != none || p.manage_inventory != none || p.origin_country != none
		|| p.mid_code != none || p.material != none || p.weight != none || p.length != none
		|| p.height != none || p.width != none {
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

fn conduit_product_variant_delete(mut app App, mut ctx Context, variant_id_bin []u8) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error(mut ctx, http.Status.internal_server_error, error_transaction_start,
			err.msg())
	}

	model_product_variant_delete(mut tx, variant_id_bin) or {
		tx.rollback() or {}
		return handle_error(mut ctx, http.Status.internal_server_error, 'Could not delete product_variant',
			err.msg())
	}

	tx.commit() or {
		return handle_error(mut ctx, http.Status.internal_server_error, error_transaction_commit,
			err.msg())
	}

	return success(mut ctx)
}
