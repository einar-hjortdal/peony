module peony

import arrays
import veb

// TODO split store/admin conduit to fetch only data required by the endpoint
fn conduit_category_list(mut app App, mut ctx Context, p CategoryRetrieveParams) veb.Result {
	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	count := model_category_retrieve_count(mut tx, p) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not retrieve category count', err.msg())
		return ctx.handle_error(perr)
	}

	if count == 0 {
		tx.rollback() or {
			perr := new_error_internal(error_transaction_rollback, err.msg())
			return ctx.handle_error(perr)
		}

		return ctx.json(CategoryResponseListEnvelope{
			categories: []CategoryResponse{}
			count:      count
			offset:     p.offset
			fetch:      p.fetch
		})
	}

	categories := model_category_retrieve(mut tx, p) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not retrieve category', err.msg())
		return ctx.handle_error(perr)
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
		perr := new_error_internal('Could not retrieve category_translations', err.msg())
		return ctx.handle_error(perr)
	}

	seo := model_category_seo_retrieve(mut tx, categories_ids_bin) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not retrieve seo', err.msg())
		return ctx.handle_error(perr)
	}

	mut seo_ids_bin := [][]u8{len: seo.len}
	mut seo_map := map[string]CategorySEO{}
	for i := 0; i < seo.len; i++ {
		seo_id := seo[i].id
		seo_id_bin := seo[i].id_bin
		seo_ids_bin[i] = seo_id_bin
		seo_map[seo_id] = seo[i]
	}

	seo_translations := model_seo_translation_retrieve(mut tx, seo_ids_bin) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not retrieve seo_translations', err.msg())
		return ctx.handle_error(perr)
	}

	tx.rollback() or {
		perr := new_error_internal(error_transaction_commit, err.msg())
		return ctx.handle_error(perr)
	}

	for i := 0; i < translations.len; i++ {
		translation := translations[i]
		owner_id := translation.category_id
		old := categories_map[owner_id].translations
		categories_map[owner_id].translations = arrays.concat(old, translation)
	}

	for i := 0; i < seo_translations.len; i++ {
		translation := seo_translations[i]
		seo_id := translation.seo_id
		old := seo_map[seo_id].translations
		seo_map[seo_id].translations = arrays.concat(old, translation)
	}

	for i := 0; i < seo.len; i++ {
		seo_id := seo[i].id
		category_id := seo[i].category_id
		categories_map[category_id].seo = seo_map[seo_id]
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
	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	count := model_category_retrieve_count(mut tx, p) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not retrieve category count', err.msg())
		return ctx.handle_error(perr)
	}

	if count == 0 {
		tx.rollback() or {}
		perr := new_error_not_found('No category exists with the given id.', 'count == 0')
		return ctx.handle_error(perr)
	}

	categories := model_category_retrieve(mut tx, p) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not retrieve category', err.msg())
		return ctx.handle_error(perr)
	}

	translations := model_category_translations_get(mut tx, p.ids_bin) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not retrieve category_translations', err.msg())
		return ctx.handle_error(perr)
	}

	seo := model_category_seo_retrieve(mut tx, p.ids_bin) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not retrieve seo', err.msg())
		return ctx.handle_error(perr)
	}

	// there should always be one seo row.
	seo_translations := model_seo_translation_retrieve(mut tx, [seo[0].id_bin]) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not retrieve seo_translations', err.msg())
		return ctx.handle_error(perr)
	}

	tx.rollback() or {
		perr := new_error_internal(error_transaction_commit, err.msg())
		return ctx.handle_error(perr)
	}

	mut category := categories[0]

	for i := 0; i < translations.len; i++ {
		translation := translations[i]
		old := category.translations
		category.translations = arrays.concat(old, translation)
	}

	category.seo = seo[0]
	category.seo.translations = seo_translations

	external_category := format_category_response(category)

	return ctx.json(CategoryResponseEnvelope{
		category: external_category
	})
}

fn conduit_category_get_store(mut app App, mut ctx Context, locale_id string, p CategoryRetrieveParams) veb.Result {
	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	count := model_category_retrieve_count(mut tx, p) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not retrieve category count', err.msg())
		return ctx.handle_error(perr)
	}

	if count == 0 {
		tx.rollback() or {}
		perr := new_error_not_found('No category exists with the given id.', 'count == 0')
		return ctx.handle_error(perr)
	}

	categories := model_category_retrieve(mut tx, p) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not retrieve category', err.msg())
		return ctx.handle_error(perr)
	}

	tx.rollback() or {
		perr := new_error_internal(error_transaction_commit, err.msg())
		return ctx.handle_error(perr)
	}

	mut category := categories[0]

	external_category := format_category_response_store(category, locale_id)

	return ctx.json(CategoryResponseStoreEnvelope{
		category: external_category
	})
}

fn conduit_category_create(mut app App, mut ctx Context, ph CategoryCreateRequestHygienised) veb.Result {
	category_id, category_id_bin := app.new_id()

	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	model_category_create(mut tx, category_id, category_id_bin, ph) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not create category', err.msg())
		return ctx.handle_error(perr)
	}

	if translations := ph.translations {
		if translations.len > 0 {
			model_category_translations_update(mut tx, category_id_bin, translations) or {
				tx.rollback() or {}
				perr := new_error_internal('Could not create category_translations', err.msg())
				return ctx.handle_error(perr)
			}
		}
	}

	_, seo_id_bin := app.new_id()
	if seo := ph.seo {
		model_category_seo_create(mut tx, seo_id_bin, category_id_bin, seo) or {
			tx.rollback() or {} // ignore error
			perr := new_error_internal('Failed to insert seo data', err.msg())
			return ctx.handle_error(perr)
		}

		if translations := seo.translations {
			if translations.len > 0 {
				model_seo_translations_create(mut tx, seo_id_bin, translations) or {
					tx.rollback() or {} // ignore error
					perr := new_error_internal('Failed to insert seo_translations data',
						err.msg())
					return ctx.handle_error(perr)
				}
			}
		}
	} else {
		model_category_seo_create_default(mut tx, seo_id_bin, category_id_bin) or {
			tx.rollback() or {} // ignore error
			perr := new_error_internal('Failed to insert default seo data', err.msg())
			return ctx.handle_error(perr)
		}
	}

	tx.commit() or {
		tx.rollback() or {}
		perr := new_error_internal(error_transaction_commit, err.msg())
		return ctx.handle_error(perr)
	}

	return success(mut ctx)
}

fn conduit_category_update(mut app App, mut ctx Context, category_id_bin []u8, seo_id_bin []u8, ph CategoryUpdateRequestHygienised) veb.Result {
	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	model_category_update(mut tx, category_id_bin, ph) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not update category', err.msg())
		return ctx.handle_error(perr)
	}

	if translations := ph.translations {
		model_category_translations_delete(mut tx, category_id_bin) or {
			tx.rollback() or {}
			perr := new_error_internal('Could not delete category_translations', err.msg())
			return ctx.handle_error(perr)
		}

		if translations.len > 0 {
			model_category_translations_update(mut tx, category_id_bin, translations) or {
				tx.rollback() or {}
				perr := new_error_internal('Could not update category_translations', err.msg())
				return ctx.handle_error(perr)
			}
		}
	}

	if seo := ph.seo {
		if seo.title != none || seo.description != none {
			model_seo_update(mut tx, seo_id_bin, seo) or {
				tx.rollback() or {}
				perr := new_error_internal('Could not update seo', err.msg())
				return ctx.handle_error(perr)
			}
		}

		if translations := seo.translations {
			model_seo_translations_delete(mut tx, seo_id_bin) or {
				tx.rollback() or {}
				perr := new_error_internal('Could not delete seo_translations', err.msg())
				return ctx.handle_error(perr)
			}

			if translations.len > 0 {
				model_seo_translations_create(mut tx, seo_id_bin, translations) or {
					tx.rollback() or {}
					perr := new_error_internal('Could not update seo_translations', err.msg())
					return ctx.handle_error(perr)
				}
			}
		}
	}

	tx.commit() or {
		tx.rollback() or {}
		perr := new_error_internal(error_transaction_commit, err.msg())
		return ctx.handle_error(perr)
	}

	return success(mut ctx)
}

fn conduit_category_delete(mut app App, mut ctx Context, category_id_bin []u8) veb.Result {
	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	model_category_delete(mut tx, category_id_bin) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not delete category', err.msg())
		return ctx.handle_error(perr)
	}

	tx.commit() or {
		tx.rollback() or {}
		perr := new_error_internal(error_transaction_commit, err.msg())
		return ctx.handle_error(perr)
	}

	return success(mut ctx)
}
