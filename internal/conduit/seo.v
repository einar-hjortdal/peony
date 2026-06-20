module conduit

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
