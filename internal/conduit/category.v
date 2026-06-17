module conduit

import arrays
import einar_hjortdal.firebird
import record
import internal.errors
import internal.common

pub fn category_list_count(mut tx firebird.ClientTransaction, p CategoryRetrieveParams) !i64 {
	count := record.category_retrieve_count(mut tx, p) or {
		return errors.internal('Could not retrieve category count', err.msg())
	}
	return count
}

// TODO split store/admin conduit to fetch only data required by the endpoint
pub fn category_list(mut tx firebird.ClientTransaction, p CategoryRetrieveParams) ![]Category {
	categories := record.category_retrieve(mut tx, p) or {
		return errors.internal('Could not retrieve category', err.msg())
	}

	mut categories_map, categories_ids := common.make_identifiable_map(categories)

	translations := record.category_translations_get(mut tx, categories_ids) or {
		return errors.internal('Could not retrieve category_translations', err.msg())
	}

	seo := record.category_seo_retrieve(mut tx, categories_ids) or {
		return errors.internal('Could not retrieve seo', err.msg())
	}

	mut seo_map, seo_ids := common.make_identifiable_map(seo)

	seo_translations := record.seo_translation_retrieve(mut tx, seo_ids) or {
		return errors.internal('Could not retrieve seo_translations', err.msg())
	}

	for i := 0; i < translations.len; i++ {
		translation := translations[i]
		owner_id := translation.category_id
		old := categories_map[owner_id.string()].translations
		categories_map[owner_id.string()].translations = arrays.concat(old, translation)
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
	return complete_categories
}

pub fn category_get(mut tx firebird.ClientTransaction, category_id ID) !Category {
	categories := record.category_retrieve(mut tx, CategoryRetrieveParams{
		ids:          [category_id]
		with_deleted: false
		offset:       offset_default
		fetch:        1
		order:        order_default
	}) or { return errors.internal('Could not retrieve category', err.msg()) }

	if categories.len == 0 {
		return errors.not_found('category not found',
			'No category exists with id `${category_id.string()}`')
	}

	mut category := categories[0]

	translations := record.category_translations_get(mut tx, [category_id]) or {
		return errors.internal('Could not retrieve category_translations', err.msg())
	}

	seos := record.category_seo_retrieve(mut tx, [category_id]) or {
		return errors.internal('Could not retrieve seo', err.msg())
	}

	mut seo := seos[0]

	// there should always be one seo row.
	seo_transaltions := record.seo_translation_retrieve(mut tx, [seo.id]) or {
		return errors.internal('Could not retrieve seo_translations', err.msg())
	}

	seo.translations = seo_transaltions
	category.seo = seo

	for i := 0; i < translations.len; i++ {
		translation := translations[i]
		old := category.translations
		category.translations = arrays.concat(old, translation)
	}

	return category
}

pub struct CategoryCreateData {
pub:
	category         CategoryCreateParams
	seo              CategorySEOCreateParams
	translations     ?[]CategoryTranslationUpdateParams
	seo_translations ?[]SEOTranslationCreateParams
}

fn check_category_create_data(mut tx firebird.ClientTransaction, p CategoryCreateData) ! {
	if parent_category_id := p.category.parent_category_id {
		count := record.category_retrieve_count(mut tx, CategoryRetrieveParams{
			ids:          [parent_category_id]
			with_deleted: true
			offset:       offset_default
			fetch:        min_fetch
			order:        order_default
		}) or { return errors.internal('Could not retrieve category count', err.msg()) }
		if count == 0 {
			return errors.unprocessable_entity(errors.msg_id_invalid,
				'No category exists with id `${parent_category_id}`')
		}
	}

	if translations := p.translations {
		check_translation_locale_ids(mut tx, translations)!
	}

	if seo_translations := p.seo_translations {
		check_translation_locale_ids(mut tx, seo_translations)!
	}
}

pub fn category_create(mut tx firebird.ClientTransaction, p CategoryCreateData) ! {
	check_category_create_data(mut tx, p)!

	record.category_create(mut tx, p.category) or {
		return errors.internal('Could not create category', err.msg())
	}

	record.category_seo_create(mut tx, p.seo) or {
		return errors.internal('Failed to insert seo data', err.msg())
	}

	if translations := p.translations {
		if translations.len > 0 {
			record.category_translations_update(mut tx, p.category.id, translations) or {
				return errors.internal('Could not create category_translations', err.msg())
			}
		}
	}

	if seo_translations := p.seo_translations {
		if seo_translations.len > 0 {
			record.seo_translations_create(mut tx, seo_translations) or {
				return errors.internal('Failed to insert seo_translations data', err.msg())
			}
		}
	}
}

pub struct CategoryUpdateData {
pub:
	category         CategoryUpdateParams
	seo              ?SEOUpdateParams
	translations     ?[]CategoryTranslationUpdateParams
	seo_translations ?[]SEOTranslationCreateParams
}

pub fn category_update(mut tx firebird.ClientTransaction, p CategoryUpdateData) ! {
	record.category_update(mut tx, p.category) or {
		return errors.internal('Could not update category', err.msg())
	}

	if translations := p.translations {
		record.category_translations_delete(mut tx, p.category.id) or {
			return errors.internal('Could not delete category_translations', err.msg())
		}

		if translations.len > 0 {
			record.category_translations_update(mut tx, p.category.id, translations) or {
				return errors.internal('Could not update category_translations', err.msg())
			}
		}
	}

	if seo := p.seo {
		if seo.title != none || seo.description != none {
			record.seo_update(mut tx, seo) or {
				return errors.internal('Could not update seo', err.msg())
			}
		}
	}

	if translations := p.seo_translations {
		record.category_seo_translations_delete(mut tx, p.category.id) or {
			return errors.internal('Could not delete seo_translations', err.msg())
		}

		if translations.len > 0 {
			record.seo_translations_create(mut tx, translations) or {
				return errors.internal('Could not update seo_translations', err.msg())
			}
		}
	}
}

pub fn category_delete(mut tx firebird.ClientTransaction, category_id ID) ! {
	record.category_delete(mut tx, category_id) or {
		return errors.internal('Could not delete category', err.msg())
	}
}
