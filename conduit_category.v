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

	mut categories_map, categories_ids := make_identifiable_map(categories)

	translations := model_category_translations_get(mut tx, categories_ids) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not retrieve category_translations', err.msg())
		return ctx.handle_error(perr)
	}

	seo := model_category_seo_retrieve(mut tx, categories_ids) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not retrieve seo', err.msg())
		return ctx.handle_error(perr)
	}

	mut seo_map, seo_ids := make_identifiable_map(seo)

	seo_translations := model_seo_translation_retrieve(mut tx, seo_ids) or {
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
		owner_id := translation.category_id.string()
		old := categories_map[owner_id].translations
		categories_map[owner_id].translations = arrays.concat(old, translation)
	}

	for i := 0; i < seo_translations.len; i++ {
		translation := seo_translations[i]
		seo_id := translation.seo_id
		old := seo_map[seo_id.string()].translations
		seo_map[seo_id.string()].translations = arrays.concat(old, translation)
	}

	for i := 0; i < seo.len; i++ {
		seo_id := seo[i].id
		category_id := seo[i].category_id
		categories_map[category_id.string()].seo = seo_map[seo_id.string()]
	}

	mut complete_categories := []Category{len: categories_ids.len}
	for i := 0; i < categories_ids.len; i++ {
		id := categories_ids[i]
		complete_categories[i] = categories_map[id.string()]
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
	category_ids := p.ids or {
		return ctx.handle_error(new_error_internal('id missing', 'received no category ids'))
	}

	if category_ids.len != 1 {
		return ctx.handle_error(new_error_internal('id missing', 'received bad number of ids'))
	}

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

	translations := model_category_translations_get(mut tx, category_ids) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not retrieve category_translations', err.msg())
		return ctx.handle_error(perr)
	}

	seo := model_category_seo_retrieve(mut tx, category_ids) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not retrieve seo', err.msg())
		return ctx.handle_error(perr)
	}

	// there should always be one seo row.
	seo_translations := model_seo_translation_retrieve(mut tx, [seo[0].id]) or {
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
	category_id := app.gen_id()

	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	model_category_create(mut tx, category_id, ph) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not create category', err.msg())
		return ctx.handle_error(perr)
	}

	if translations := ph.translations {
		if translations.len > 0 {
			model_category_translations_update(mut tx, category_id, translations) or {
				tx.rollback() or {}
				perr := new_error_internal('Could not create category_translations', err.msg())
				return ctx.handle_error(perr)
			}
		}
	}

	seo_id := app.gen_id()
	if seo := ph.seo {
		model_category_seo_create(mut tx, seo_id, category_id, seo) or {
			tx.rollback() or {} // ignore error
			perr := new_error_internal('Failed to insert seo data', err.msg())
			return ctx.handle_error(perr)
		}

		if translations := seo.translations {
			if translations.len > 0 {
				model_seo_translations_create(mut tx, seo_id, translations) or {
					tx.rollback() or {} // ignore error
					perr := new_error_internal('Failed to insert seo_translations data', err.msg())
					return ctx.handle_error(perr)
				}
			}
		}
	} else {
		model_category_seo_create_default(mut tx, seo_id, category_id) or {
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

fn conduit_category_update(mut app App, mut ctx Context, category_id ID, seo_id ID, ph CategoryUpdateRequestHygienised) veb.Result {
	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	model_category_update(mut tx, category_id, ph) or {
		tx.rollback() or {}
		perr := new_error_internal('Could not update category', err.msg())
		return ctx.handle_error(perr)
	}

	if translations := ph.translations {
		model_category_translations_delete(mut tx, category_id) or {
			tx.rollback() or {}
			perr := new_error_internal('Could not delete category_translations', err.msg())
			return ctx.handle_error(perr)
		}

		if translations.len > 0 {
			model_category_translations_update(mut tx, category_id, translations) or {
				tx.rollback() or {}
				perr := new_error_internal('Could not update category_translations', err.msg())
				return ctx.handle_error(perr)
			}
		}
	}

	if seo := ph.seo {
		if seo.title != none || seo.description != none {
			model_seo_update(mut tx, seo_id, seo) or {
				tx.rollback() or {}
				perr := new_error_internal('Could not update seo', err.msg())
				return ctx.handle_error(perr)
			}
		}

		if translations := seo.translations {
			model_seo_translations_delete(mut tx, seo_id) or {
				tx.rollback() or {}
				perr := new_error_internal('Could not delete seo_translations', err.msg())
				return ctx.handle_error(perr)
			}

			if translations.len > 0 {
				model_seo_translations_create(mut tx, seo_id, translations) or {
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

fn conduit_category_delete(mut app App, mut ctx Context, category_id ID) veb.Result {
	mut tx := app.start_transaction() or { return ctx.handle_error(err) }

	model_category_delete(mut tx, category_id) or {
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

