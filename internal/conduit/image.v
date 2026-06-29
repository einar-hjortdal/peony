module conduit

import einar_hjortdal.firebird
import einar_hjortdal.luuid
import internal.common
import internal.errors
import record

pub struct ImageTranslationCreateParams {
pub:
	// image_id  ID
	locale_id ID
	alt       string
}

pub struct ImageCreateParams {
	url          ?string
	alt          ?string
	translations ?[]ImageTranslationCreateParams
}

pub struct ProductImageCreateParams {
	ImageCreateParams
pub:
	// id           ?string
	product_id ID
	image_rank ?i32
}

pub fn product_image_create(mut tx firebird.ClientTransaction, mut g luuid.Generator, p ProductImageCreateParams) !ID {
	image_id := common.new_id(mut g)

	record.product_image_create(mut tx, product_id, i) or {
		return errors.internal('Failed to create product_image', err.msg())
	}

	if translations := p.translations {
		if translations.len > 0 {
			// create image translations
		}
	}

	return image_id
}
