module main

import einar_hjortdal.firebird

struct ProductVariantTranslation {
	product_variant_id string
	locale_code        string
	created_at         firebird.DateTime
	updated_at         firebird.DateTime
	deleted_at         firebird.DateTime @[omitempty]
	title              string
}
