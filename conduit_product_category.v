module peony

import arrays
import veb

fn conduit_product_category_list(mut app App, mut ctx Context, ph ProductCategoryParamsHygienised) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	count := model_product_category_retrieve_count(mut tx, ph) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve product_category count',
			err.msg())
	}

	if count == 0 {
		tx.rollback() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }
		return ctx.json(ProductCategoryResponseListEnvelope{
			product_categories: []ProductCategoryResponse{}
			count:              count
			offset:             get_offset_amount(ph.offset)
			fetch:              ph.fetch.v
		})
	}

	internal_product_categories := model_product_category_retrieve(mut tx, ph) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve product_category', err.msg())
	}

	mut ipc_map := map[string]ProductCategory{}
	mut ipc_ids := []string{len: internal_product_categories.len}
	mut ipc_ids_bin := [][]u8{len: internal_product_categories.len}
	for i := 0; i < internal_product_categories.len; i++ {
		pc := internal_product_categories[i]
		id_string := pc.id
		ipc_map[id_string] = pc
		ipc_ids[i] = pc.id
		ipc_ids_bin[i] = pc.id_bin
	}

	translations := model_product_category_translations_get(mut tx, ipc_ids_bin) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve product_category_translations from database',
			err.msg())
	}

	for i := 0; i < translations.len; i++ {
		translation := translations[i]
		owner_id := translation.product_category_id
		ipc_map[owner_id].translations = arrays.concat(ipc_map[owner_id].translations,
			translation)
	}

	mut ipc := []ProductCategory{len: ipc_ids.len}
	for i := 0; i < ipc_ids.len; i++ {
		id := ipc_ids[i]
		ipc[i] = ipc_map[id]
	}

	tx.rollback() or { return handle_error_500(mut ctx, error_transaction_commit, err.msg()) }

	mut external_product_categories := []ProductCategoryResponse{len: ipc.len}
	for i := 0; i < ipc.len; i++ {
		external_product_categories[i] = format_product_category_response(ipc[i])
	}

	return ctx.json(ProductCategoryResponseListEnvelope{
		product_categories: external_product_categories
		count:              count
		offset:             get_offset_amount(ph.offset)
		fetch:              ph.fetch.v
	})
}

fn conduit_product_category_create(mut app App, mut ctx Context, ph ProductCategoryRequestHygienised, pcth []ProductCategoryTranslationRequestHygienised) veb.Result {
	id, id_bin := app.new_id()

	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	model_product_category_create(mut tx, id, id_bin, ph) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not create product_category', err.msg())
	}

	model_product_category_translations_merge(mut tx, id_bin, pcth) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not create product_category_translations',
			err.msg())
	}

	tx.commit() or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, error_transaction_commit, err.msg())
	}

	return success(mut ctx)
}

fn conduit_product_category_update(mut app App, mut ctx Context, product_category_id_bin []u8, ph ProductCategoryRequestHygienised) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	model_product_category_update(mut tx, product_category_id_bin, ph) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not update product_category', err.msg())
	}

	if translations := ph.translations {
		model_product_category_translations_merge(mut tx, product_category_id_bin, translations) or {
			tx.rollback() or {}
			return handle_error_500(mut ctx, 'Could not update product_category_translations',
				err.msg())
		}
	}

	tx.commit() or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, error_transaction_commit, err.msg())
	}

	return success(mut ctx)
}

fn conduit_product_category_delete(mut app App, mut ctx Context, product_category_id_bin []u8) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	model_product_category_delete(mut tx, product_category_id_bin) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not delete product_category', err.msg())
	}

	tx.commit() or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, error_transaction_commit, err.msg())
	}

	return success(mut ctx)
}
