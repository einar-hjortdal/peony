module peony

import arrays
import veb

// TODO split store/admin conduit to fetch only data required by the endpoint
fn conduit_category_list(mut app App, mut ctx Context, p CategoryRetrieveParams) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	count := model_category_retrieve_count(mut tx, p) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve category count', err.msg())
	}

	if count == 0 {
		tx.rollback() or { return handle_error_500(mut ctx, error_transaction_rollback, err.msg()) }
		return ctx.json(CategoryResponseListEnvelope{
			categories: []CategoryResponse{}
			count:      count
			offset:     p.offset
			fetch:      p.fetch
		})
	}

	categories := model_category_retrieve(mut tx, p) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve category', err.msg())
	}

	mut categories_map := map[string]Category{}
	mut categories_ids := []string{len: categories.len}
	mut categories_ids_bin := [][]u8{len: categories.len}
	for i := 0; i < categories.len; i++ {
		pc := categories[i]
		id_string := pc.id
		categories_map[id_string] = pc
		categories_ids[i] = pc.id
		categories_ids_bin[i] = pc.id_bin
	}

	translations := model_category_translations_get(mut tx, categories_ids_bin) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve category_translations', err.msg())
	}

	seo_translations := model_category_seo_retrieve(mut tx, categories_ids_bin) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve seo_translations', err.msg())
	}

	tx.rollback() or { return handle_error_500(mut ctx, error_transaction_commit, err.msg()) }

	for i := 0; i < translations.len; i++ {
		translation := translations[i]
		owner_id := translation.category_id
		old := categories_map[owner_id].translations
		categories_map[owner_id].translations = arrays.concat(old, translation)
	}

	for i := 0; i < seo_translations.len; i++ {
		seo_translation := seo_translations[i]
		owner_id := seo_translation.category_id
		old := categories_map[owner_id].seo_translations
		categories_map[owner_id].seo_translations = arrays.concat(old, seo_translation)
	}

	mut complete_categories := []Category{len: categories_ids.len}
	for i := 0; i < categories_ids.len; i++ {
		id := categories_ids[i]
		complete_categories[i] = categories_map[id]
	}

	mut external_categories := []CategoryResponse{len: complete_categories.len}
	for i := 0; i < complete_categories.len; i++ {
		external_categories[i] = format_category_response(complete_categories[i])
	}

	return ctx.json(CategoryResponseListEnvelope{
		categories: external_categories
		count:      count
		offset:     p.offset
		fetch:      p.fetch
	})
}

fn conduit_category_get(mut app App, mut ctx Context, p CategoryRetrieveParams) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	count := model_category_retrieve_count(mut tx, p) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve category count', err.msg())
	}

	if count == 0 {
		tx.rollback() or {}
		return handle_error_404(mut ctx, 'Not found', 'No category exists with the given id.')
	}

	categories := model_category_retrieve(mut tx, p) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve category', err.msg())
	}

	translations := model_category_translations_get(mut tx, p.ids_bin) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve category_translations from database',
			err.msg())
	}

	seo_translations := model_category_seo_retrieve(mut tx, p.ids_bin) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve seo_translations', err.msg())
	}

	tx.rollback() or { return handle_error_500(mut ctx, error_transaction_commit, err.msg()) }

	mut category := categories[0]

	for i := 0; i < translations.len; i++ {
		translation := translations[i]
		old := category.translations
		category.translations = arrays.concat(old, translation)
	}

	for i := 0; i < seo_translations.len; i++ {
		seo_translation := seo_translations[i]
		old := category.seo_translations
		category.seo_translations = arrays.concat(old, seo_translation)
	}

	external_category := format_category_response(category)

	return ctx.json(CategoryResponseEnvelope{
		category: external_category
	})
}

fn conduit_category_get_store(mut app App, mut ctx Context, p CategoryRetrieveParams) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	count := model_category_retrieve_count(mut tx, p) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve category count', err.msg())
	}

	if count == 0 {
		tx.rollback() or {}
		return handle_error_404(mut ctx, 'Not found', 'No category exists with the given id.')
	}

	categories := model_category_retrieve(mut tx, p) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not retrieve category', err.msg())
	}

	tx.rollback() or { return handle_error_500(mut ctx, error_transaction_commit, err.msg()) }

	mut category := categories[0]

	external_category := format_category_response_store(category)

	return ctx.json(CategoryResponseStoreEnvelope{
		category: external_category
	})
}

fn conduit_category_create(mut app App, mut ctx Context, ph CategoryCreateRequestHygienised) veb.Result {
	category_id, category_id_bin := app.new_id()

	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	model_category_create(mut tx, category_id, category_id_bin, ph) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not create category', err.msg())
	}

	model_category_translations_update(mut tx, category_id_bin, ph.translations) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not create category_translations', err.msg())
	}

	if seo_translations := ph.seo_translations {
		mut seo_translation_ids_bin := [][]u8{len: seo_translations.len}
		for i := 0; i < seo_translations.len; i++ {
			_, id_bin := app.new_id()
			seo_translation_ids_bin[i] = id_bin
		}

		p := CategorySEOUpdateParams{
			category_id_bin:         category_id_bin
			seo_translation_ids_bin: seo_translation_ids_bin
			seo_translations:        seo_translations
		}

		model_category_seo_update(mut tx, p) or {
			tx.rollback() or {}
			return handle_error_500(mut ctx, 'Could not create seo_translations', err.msg())
		}
	}

	tx.commit() or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, error_transaction_commit, err.msg())
	}

	return success(mut ctx)
}

fn conduit_category_update(mut app App, mut ctx Context, category_id_bin []u8, ph CategoryUpdateRequestHygienised) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	model_category_update(mut tx, category_id_bin, ph) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not update category', err.msg())
	}

	if translations := ph.translations {
		model_category_translations_update(mut tx, category_id_bin, translations) or {
			tx.rollback() or {}
			return handle_error_500(mut ctx, 'Could not update category_translations',
				err.msg())
		}
	}

	tx.commit() or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, error_transaction_commit, err.msg())
	}

	return success(mut ctx)
}

fn conduit_category_delete(mut app App, mut ctx Context, category_id_bin []u8) veb.Result {
	mut tx := app.start_transaction() or {
		return handle_error_500(mut ctx, error_transaction_start, err.msg())
	}

	model_category_delete(mut tx, category_id_bin) or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, 'Could not delete category', err.msg())
	}

	tx.commit() or {
		tx.rollback() or {}
		return handle_error_500(mut ctx, error_transaction_commit, err.msg())
	}

	return success(mut ctx)
}
