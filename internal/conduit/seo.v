module conduit

import record
import internal.common

pub struct SEOTranslationParams {
pub:
	locale_id   common.ID
	title       ?string
	description ?string
}

fn (p SEOTranslationParams) locale_id() common.ID {
	return p.locale_id
}

fn (p SEOTranslationParams) parse(seo_id common.ID) record.SEOTranslationCreateParams {
	return record.SEOTranslationCreateParams{
		seo_id:      seo_id
		locale_id:   p.locale_id
		title:       p.title
		description: p.description
	}
}

pub struct SEOParams {
pub:
	title        ?string
	description  ?string
	translations ?[]SEOTranslationParams
}

fn (p SEOParams) parse_update(id common.ID) record.SEOUpdateParams {
	return SEOUpdateParams{
		id:          id
		title:       p.title
		description: p.description
	}
}

fn (p SEOParams) parse_category_create(id common.ID, category_id common.ID) record.CategorySEOCreateParams {
	return record.CategorySEOCreateParams{
		id:          id
		title:       p.title
		description: p.description
		category_id: category_id
	}
}

fn (p SEOParams) parse_product_create(id common.ID, product_id common.ID) record.ProductSEOCreateParams {
	return record.ProductSEOCreateParams{
		id:          id
		title:       p.title
		description: p.description
		product_id:  product_id
	}
}
