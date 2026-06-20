module conduit

import record

pub struct SEOTranslationParams {
pub:
	locale_id   ID
	title       ?string
	description ?string
}

fn (p SEOTranslationParams) locale_id() ID {
	return p.locale_id
}

pub struct SEOParams {
pub:
	title        ?string
	description  ?string
	translations ?[]SEOTranslationParams
}

fn (p SEOParams) parse_translation_params(seo_id ID) ?[]record.SEOTranslationCreateParams {
	t := p.translations or { return none }

	mut res := []record.SEOTranslationCreateParams{len: t.len}
	for i := 0; i < t.len; i++ {
		translation := t[i]
		res[i] = record.SEOTranslationCreateParams{
			seo_id:      seo_id
			locale_id:   translation.locale_id
			title:       translation.title
			description: translation.description
		}
	}
	return res
}

fn (p SEOParams) parse_category_create(id ID, category_id ID) record.CategorySEOCreateParams {
	return record.CategorySEOCreateParams{
		id:          id
		title:       p.title
		description: p.description
		category_id: category_id
	}
}
