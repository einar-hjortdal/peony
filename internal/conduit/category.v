module conduit

import arrays
import einar_hjortdal.firebird
import einar_hjortdal.luuid
import einar_hjortdal.slugify
import record
import internal.errors
import internal.common

// TODO split store/admin conduit to fetch only data required by the endpoint
pub fn category_list(mut tx firebird.ClientTransaction, p CategoryRetrieveParams) !List[Category] {
	count := record.category_retrieve_count(mut tx, p) or {
		return errors.internal('Could not retrieve category count', err.msg())
	}

	if count == 0 {
		return List[Category]{}
	}

	categories := record.category_retrieve(mut tx, p) or {
		return errors.internal('Could not retrieve category', err.msg())
	}

	if categories.len == 0 {
		return List[Category]{
			count: count
		}
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

	return List[Category]{
		count: count
		items: complete_categories
	}
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

pub struct CategoryTranslationParams {
pub:
	locale_id   ID
	name        ?string
	description ?string
}

fn (p CategoryTranslationParams) locale_id() ID {
	return p.locale_id
}

pub struct CategoryCreateParams {
pub:
	id                 ID
	name               string
	handle             ?string
	description        ?string
	is_internal        bool
	is_active          bool
	metadata           ?string
	parent_category_id ?ID
	seo                ?SEOParams
	translations       ?[]CategoryTranslationParams
}

fn (p CategoryCreateParams) check(mut tx firebird.ClientTransaction) ! {
	if parent_category_id := p.parent_category_id {
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

	if seo := p.seo {
		if seo_translations := seo.translations {
			check_translation_locale_ids(mut tx, seo_translations)!
		}
	}
}

fn (p CategoryCreateParams) parse_translations() ?[]record.CategoryTranslationCreateParams {
	t := p.translations or { return none }
	mut res := []record.CategoryTranslationCreateParams{len: t.len}
	for i := 0; i < t.len; i++ {
		ct := t[i]
		res[i] = record.CategoryTranslationCreateParams{
			locale_id:   ct.locale_id
			name:        ct.name
			description: ct.description
		}
	}
	return res
}

fn (p CategoryCreateParams) parse_seo(seo_id ID) record.CategorySEOCreateParams {
	s := p.seo or {
		return record.CategorySEOCreateParams{
			id:          seo_id
			category_id: p.id
		}
	}

	return s.parse_category_create(seo_id, p.id)
}

fn (p CategoryCreateParams) parse_seo_translations(seo_id ID) ?[]record.SEOTranslationCreateParams {
	s := p.seo or { return none }
	return s.parse_translation_params(seo_id)
}

struct CategoryCreateData {
	category         record.CategoryCreateParams
	seo              record.CategorySEOCreateParams
	translations     ?[]record.CategoryTranslationCreateParams
	seo_translations ?[]record.SEOTranslationCreateParams
}

fn (p CategoryCreateParams) parse(mut _ firebird.ClientTransaction, mut g luuid.Generator) !CategoryCreateData {
	handle := p.handle or { slugify.default().make(p.name) } // TODO check handle is unique, if not append id, use id only if append makes handle too long
	category := record.CategoryCreateParams{
		id:                 p.id
		name:               p.name
		handle:             handle
		description:        p.description
		is_internal:        p.is_internal
		is_active:          p.is_active
		metadata:           p.metadata
		parent_category_id: p.parent_category_id
	}
	translations := p.parse_translations()

	seo_id := new_id(mut g)
	seo := p.parse_seo(seo_id)
	seo_translations := p.parse_seo_translations(seo_id)

	return CategoryCreateData{
		category:         category
		seo:              seo
		translations:     translations
		seo_translations: seo_translations
	}
}

pub fn category_create(mut tx firebird.ClientTransaction, mut g luuid.Generator, p CategoryCreateParams) ! {
	p.check(mut tx)!
	data := p.parse(mut tx, mut g)!

	record.category_create(mut tx, data.category) or {
		return errors.internal('Could not create category', err.msg())
	}

	record.category_seo_create(mut tx, data.seo) or {
		return errors.internal('Failed to insert seo data', err.msg())
	}

	if translations := data.translations {
		if translations.len > 0 {
			record.category_translations_create(mut tx, p.id, translations) or {
				return errors.internal('Could not create category_translations', err.msg())
			}
		}
	}

	if seo_translations := data.seo_translations {
		if seo_translations.len > 0 {
			record.seo_translations_create(mut tx, seo_translations) or {
				return errors.internal('Failed to insert seo_translations data', err.msg())
			}
		}
	}
}

pub struct CategoryUpdateParams {
pub:
	id                 ID
	name               ?string
	description        ?string
	handle             ?string
	is_active          ?bool
	is_internal        ?bool
	metadata           ?string
	parent_category_id ?ID
	seo                ?SEOParams
	translations       ?[]CategoryTranslationParams
}

fn (p CategoryUpdateParams) check(mut tx firebird.ClientTransaction) ! {
	count := record.category_retrieve_count(mut tx, CategoryRetrieveParams{
		ids:          [p.id]
		with_deleted: true
		offset:       offset_default
		fetch:        min_fetch
		order:        order_default
	}) or { return errors.internal('Could not retrieve category count', err.msg()) }
	if count == 0 {
		return errors.unprocessable_entity(errors.msg_id_invalid,
			'Category does not exist. No category exists with id `${p.id}`')
	}

	if parent_category_id := p.parent_category_id {
		parent_count := record.category_retrieve_count(mut tx, CategoryRetrieveParams{
			ids:          [parent_category_id]
			with_deleted: true
			offset:       offset_default
			fetch:        min_fetch
			order:        order_default
		}) or { return errors.internal('Could not retrieve category count', err.msg()) }
		if parent_count == 0 {
			return errors.unprocessable_entity(errors.msg_id_invalid,
				'Parent category does not exist. No category exists with id `${parent_category_id}`')
		}
	}

	if translations := p.translations {
		check_translation_locale_ids(mut tx, translations)!
	}

	if seo := p.seo {
		if seo_translations := seo.translations {
			check_translation_locale_ids(mut tx, seo_translations)!
		}
	}
}

fn (p CategoryUpdateParams) parse_translations() ?[]record.CategoryTranslationCreateParams {
	t := p.translations or { return none }
	mut res := []record.CategoryTranslationCreateParams{len: t.len}
	for i := 0; i < t.len; i++ {
		ct := t[i]
		res[i] = record.CategoryTranslationCreateParams{
			locale_id:   ct.locale_id
			name:        ct.name
			description: ct.description
		}
	}
	return res
}

fn (p CategoryUpdateParams) parse_seo(seo_id ID) ?record.SEOUpdateParams {
	s := p.seo or { return none }
	return s.parse_update(seo_id)
}

fn (p CategoryUpdateParams) parse_seo_translations(seo_id ID) ?[]record.SEOTranslationCreateParams {
	s := p.seo or { return none }
	return s.parse_translation_params(seo_id)
}

struct CategoryUpdateData {
	category         record.CategoryUpdateParams
	seo              ?record.SEOUpdateParams
	translations     ?[]record.CategoryTranslationCreateParams
	seo_translations ?[]record.SEOTranslationCreateParams
}

fn (p CategoryUpdateParams) parse(mut tx firebird.ClientTransaction) !CategoryUpdateData {
	category := record.CategoryUpdateParams{
		id:                 p.id
		name:               p.name
		handle:             p.handle
		description:        p.description
		is_internal:        p.is_internal
		is_active:          p.is_active
		metadata:           p.metadata
		parent_category_id: p.parent_category_id
	}
	translations := p.parse_translations()

	category_seo := record.category_seo_retrieve(mut tx, [p.id]) or {
		return errors.internal('Failed to retrieve category seo', err.msg())
	}
	if category_seo.len != 1 {
		return errors.internal('Unexpected amount of seo for the category with id `${p.id}`',
			'category_seo.len != 1')
	}

	seo_id := category_seo[0].id
	seo := p.parse_seo(seo_id)
	seo_translations := p.parse_seo_translations(seo_id)

	return CategoryUpdateData{
		category:         category
		seo:              seo
		translations:     translations
		seo_translations: seo_translations
	}
}

pub fn category_update(mut tx firebird.ClientTransaction, p CategoryUpdateParams) ! {
	p.check(mut tx)!
	data := p.parse(mut tx)!
	record.category_update(mut tx, data.category) or {
		return errors.internal('Could not update category', err.msg())
	}

	if translations := data.translations {
		record.category_translations_delete(mut tx, p.id) or {
			return errors.internal('Could not delete category_translations', err.msg())
		}

		if translations.len > 0 {
			record.category_translations_create(mut tx, p.id, translations) or {
				return errors.internal('Could not update category_translations', err.msg())
			}
		}
	}

	if seo := data.seo {
		if seo.title != none || seo.description != none {
			record.seo_update(mut tx, seo) or {
				return errors.internal('Could not update seo', err.msg())
			}
		}
	}

	if seo_translations := data.seo_translations {
		record.category_seo_translations_delete(mut tx, p.id) or {
			return errors.internal('Could not delete seo_translations', err.msg())
		}

		if seo_translations.len > 0 {
			record.seo_translations_create(mut tx, seo_translations) or {
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
