module peony

import veb

fn conduit_product_category_list(mut app App, mut ctx Context, ph ProductCategoryRetrieveParamsHygienised) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	internal_product_categories := model_product_category_get(mut tx, ph) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve product_category from database',
			err.msg())
	}

	tx.rollback() or { return handle_error_500(mut ctx, error_transaction_commit, err.msg()) }

	mut external_product_categories := []ProductCategoryResponse{len: internal_product_categories.len}
	for i := 0; i < internal_product_categories.len; i++ {
		external_product_categories[i] = format_product_category_response(internal_product_categories[i])
	}

	r := ProductCategoryResponseListEnvelope{
		product_categories: external_product_categories
		count:              0 // TODO
		offset:             get_offset_amount(ph.offset)
		fetch:              get_fetch_amount(ph.fetch)
	}

	return ctx.json(r)
}

fn conduit_product_category_create(mut app App, mut ctx Context, ph ProductCategoryRequestHygienised) veb.Result {
	return success(mut ctx)
}

fn conduit_product_category_get(mut app App, mut ctx Context, product_category_id_bin []u8) veb.Result {
	return success(mut ctx)
}

fn conduit_product_category_update(mut app App, mut ctx Context, product_category_id_bin []u8, ph ProductCategoryRequestHygienised) veb.Result {
	return success(mut ctx)
}

fn conduit_product_category_delete(mut app App, mut ctx Context, product_category_id_bin []u8) veb.Result {
	return success(mut ctx)
}
