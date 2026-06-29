module conduit

import einar_hjortdal.firebird
import einar_hjortdal.luuid
import internal.common
import internal.errors
import record

pub struct ImageTranslationCreateParams {
pub:
	locale_id ID
	alt       string
}

fn parse_image_translations(translations []ImageTranslationCreateParams) []record.ImageTranslationUpdateParams {
	mut res := []record.ImageTranslationUpdateParams{len: 0, cap: translations.len}
	for _, translation in translations {
		res << record.ImageTranslationUpdateParams{
			locale_id: translation.locale_id
			alt:       translation.alt
		}
	}
	return res
}

pub struct ImageCreateParams {
pub:
	url          string
	alt          ?string
	translations ?[]ImageTranslationCreateParams
}

pub struct ProductImageCreateParams {
	ImageCreateParams
pub:
	product_id ID
	image_rank ?i32
}

pub fn product_image_get(mut tx firebird.ClientTransaction, product_id ID, image_id ID) !ProductImage {
	images := record.product_image_retrieve(mut tx, record.ProductImageRetrieveParams{
		image_ids:   [image_id]
		product_ids: [product_id]
	}) or { return errors.internal('Failed to retrieve image', err.msg()) }

	if images.len == 0 {
		return errors.not_found('Image with id ${image_id.string()} does not exist or does not belong to product',
			'images.len == 0')
	}

	return images[0]
}

pub fn product_image_create(mut tx firebird.ClientTransaction, mut g luuid.Generator, p ProductImageCreateParams) !ID {
	image_id := common.new_id(mut g)

	record.image_create(mut tx, [
		record.ImageCreateParams{
			id:  image_id
			url: p.url
			alt: p.alt
		},
	]) or { return errors.internal('Failed to create image', err.msg()) }

	if translations := p.translations {
		t := parse_image_translations(translations)
		record.image_translation_update(mut tx, [image_id], t) or {
			return errors.internal('Failed to create image_translations', err.msg())
		}
	}

	record.product_image_create_one(mut tx, p.product_id, image_id) or {
		return errors.internal('Failed to create product_image', err.msg())
	}

	return image_id
}

pub struct ImageUpdateParams {
pub:
	id           ID
	url          ?string
	alt          ?string
	translations ?[]ImageTranslationCreateParams
}

pub fn product_image_update(mut tx firebird.ClientTransaction, p ImageUpdateParams) ! {
	if p.url != none && p.alt != none {
		current := record.image_retrieve(mut tx, [p.id]) or {
			return errors.internal('Failed to retrieve image', err.msg())
		}

		diff := record.ImageUpdateParams{
			id:  p.id
			url: common.unwrap_option_or(p.url, current.url)
			alt: common.unwrap_option_or_option(p.alt, current.alt)
		}
		record.image_update(mut tx, [diff]) or {
			return errors.internal('Failed to update image', err.msg())
		}
	}

	if translations := p.translations {
		t := parse_image_translations(translations)
		record.image_translation_update(mut tx, [p.id], t) or {
			return errors.internal('Failed to update image_translations', err.msg())
		}
	}
}

pub fn product_image_delete(mut tx firebird.ClientTransaction, product_id ID, image_id ID) ! {
	images := record.product_image_retrieve(mut tx, record.ProductImageRetrieveParams{
		image_ids:   [image_id]
		product_ids: [product_id]
	}) or { return errors.internal('Failed to retrieve image', err.msg()) }

	if images.len == 0 {
		return errors.not_found('Image with id ${image_id.string()} does not exist or does not belong to product',
			'images.len == 0')
	}

	record.image_delete(mut tx, [image_id]) or {
		return errors.internal('Failed to delete product image', err.msg())
	}
}
