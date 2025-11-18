module peony

import arrays
import veb

fn conduit_product_category_list(mut app App, mut ctx Context, p ProductCategoryRetrieveParams) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	count := model_product_category_retrieve_count(mut tx, p) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve product_category count',
			err.msg())
	}

	if count == 0 {
		tx.rollback() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }
		return ctx.json(ProductCategoryResponseListEnvelope{
			product_categories: []ProductCategoryResponse{}
			count:              count
			offset:             p.offset
			fetch:              p.fetch
		})
	}

	product_categories := model_product_category_retrieve(mut tx, p) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve product_category', err.msg())
	}

	mut product_categories_map := map[string]ProductCategory{}
	mut product_categories_ids := []string{len: product_categories.len}
	mut product_categories_ids_bin := [][]u8{len: product_categories.len}
	for i := 0; i < product_categories.len; i++ {
		pc := product_categories[i]
		id_string := pc.id
		product_categories_map[id_string] = pc
		product_categories_ids[i] = pc.id
		product_categories_ids_bin[i] = pc.id_bin
	}

	// TODO split endpoint for store: store does not need to get translations and seo_translations
	translations := model_product_category_translations_get(mut tx, product_categories_ids_bin) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve product_category_translations',
			err.msg())
	}

	seo_translations := model_product_category_seo_retrieve(mut tx, product_categories_ids_bin) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve seo_translations', err.msg())
	}

	tx.rollback() or { return handle_error_500(mut ctx, error_transaction_commit, err.msg()) }

	for i := 0; i < translations.len; i++ {
		translation := translations[i]
		owner_id := translation.product_category_id
		old := product_categories_map[owner_id].translations
		product_categories_map[owner_id].translations = arrays.concat(old, translation)
	}

	for i := 0; i < seo_translations.len; i++ {
		seo_translation := seo_translations[i]
		owner_id := seo_translation.product_category_id
		old := product_categories_map[owner_id].seo_translations
		product_categories_map[owner_id].seo_translations = arrays.concat(old, seo_translation)
	}

	mut complete_product_categories := []ProductCategory{len: product_categories_ids.len}
	for i := 0; i < product_categories_ids.len; i++ {
		id := product_categories_ids[i]
		complete_product_categories[i] = product_categories_map[id]
	}

	mut external_product_categories := []ProductCategoryResponse{len: complete_product_categories.len}
	for i := 0; i < complete_product_categories.len; i++ {
		external_product_categories[i] = format_product_category_response(complete_product_categories[i])
	}

	mut child_to_parent_map := map[string]string{}
	for i := 0; i < complete_product_categories.len; i++ {
		cpc := complete_product_categories[i]
		id := cpc.id
		parent_id := cpc.parent_category_id
		child_to_parent_map[id] = parent_id
	}

	mut external_product_categories_map := map[string]ProductCategoryResponse{}
	for i := 0; i < external_product_categories.len; i++ {
		epc := external_product_categories[i]
		id := epc.id
		external_product_categories_map[id] = epc
	}

	for id, parent_id in child_to_parent_map {
		if parent_id == '' {
			continue
		}
		epc := external_product_categories_map[id]
		mut epc_parent := external_product_categories_map[parent_id]
		old := epc_parent.children
		epc_parent.children = arrays.concat(old, epc)
		external_product_categories_map[parent_id] = epc_parent
	}

	mut root_categories := []ProductCategoryResponse{}
	for i := 0; i < complete_product_categories.len; i++ {
		cpc := complete_product_categories[i]
		if cpc.parent_category_id == '' {
			id := cpc.id
			epc := external_product_categories_map[id]
			root_categories = arrays.concat(root_categories, epc)
		}
	}

	return ctx.json(ProductCategoryResponseListEnvelope{
		product_categories: root_categories
		count:              count
		offset:             p.offset
		fetch:              p.fetch
	})
}

fn conduit_product_category_get(mut app App, mut ctx Context, product_category_id string, product_category_id_bin []u8, p ProductCategoryRetrieveParams) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	count := model_product_category_retrieve_count(mut tx, p) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve product_category count',
			err.msg())
	}

	if count == 0 {
		tx.rollback() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }
		return handle_error_404(mut ctx, '', '') // TODO
	}

	product_categories := model_product_category_retrieve(mut tx, p) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve product_category', err.msg())
	}

	mut product_categories_map := map[string]ProductCategory{}
	mut product_categories_ids := []string{len: product_categories.len}
	mut product_categories_ids_bin := [][]u8{len: product_categories.len}
	for i := 0; i < product_categories.len; i++ {
		pc := product_categories[i]
		id_string := pc.id
		product_categories_map[id_string] = pc
		product_categories_ids[i] = pc.id
		product_categories_ids_bin[i] = pc.id_bin
	}

	translations := model_product_category_translations_get(mut tx, product_categories_ids_bin) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve product_category_translations from database',
			err.msg())
	}

	seo_translations := model_product_category_seo_retrieve(mut tx, product_categories_ids_bin) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve seo_translations', err.msg())
	}

	tx.rollback() or { return handle_error_500(mut ctx, error_transaction_commit, err.msg()) }

	for i := 0; i < translations.len; i++ {
		translation := translations[i]
		owner_id := translation.product_category_id
		product_categories_map[owner_id].translations = arrays.concat(product_categories_map[owner_id].translations,
			translation)
	}

	for i := 0; i < seo_translations.len; i++ {
		seo_translation := seo_translations[i]
		owner_id := seo_translation.product_category_id
		old := product_categories_map[owner_id].seo_translations
		product_categories_map[owner_id].seo_translations = arrays.concat(old, seo_translation)
	}

	mut complete_product_categories := []ProductCategory{len: product_categories_ids.len}
	for i := 0; i < product_categories_ids.len; i++ {
		id := product_categories_ids[i]
		complete_product_categories[i] = product_categories_map[id]
	}

	mut external_product_categories := []ProductCategoryResponse{len: complete_product_categories.len}
	for i := 0; i < complete_product_categories.len; i++ {
		external_product_categories[i] = format_product_category_response(complete_product_categories[i])
	}

	mut child_to_parent_map := map[string]string{}
	for i := 0; i < complete_product_categories.len; i++ {
		cpc := complete_product_categories[i]
		id := cpc.id
		parent_id := cpc.parent_category_id
		child_to_parent_map[id] = parent_id
	}

	mut external_product_categories_map := map[string]ProductCategoryResponse{}
	for i := 0; i < external_product_categories.len; i++ {
		epc := external_product_categories[i]
		id := epc.id
		external_product_categories_map[id] = epc
	}

	for id, parent_id in child_to_parent_map {
		if parent_id == '' {
			continue
		}
		epc := external_product_categories_map[id]
		mut epc_parent := external_product_categories_map[parent_id]
		old := epc_parent.children
		epc_parent.children = arrays.concat(old, epc)
		external_product_categories_map[parent_id] = epc_parent
	}

	root_category := external_product_categories_map[product_category_id]

	return ctx.json(ProductCategoryResponseEnvelope{
		product_category: root_category
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
