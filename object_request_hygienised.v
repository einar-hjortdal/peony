module peony

struct StoreRequestHygienised {
	name                          ?string
	default_locale_id             ?string
	default_locale_id_bin         []u8
	default_region_id             ?string
	default_region_id_bin         []u8
	default_stock_location_id     ?string
	default_stock_location_id_bin []u8
	default_sales_channel_id      ?string
	default_sales_channel_id_bin  []u8
	locale_ids                    ?[]string
	locale_ids_bin                [][]u8
	currency_codes                ?[]string
}

fn hygienise_store_request(p StoreRequest) !StoreRequestHygienised {
	default_locale_id_bin := option_id_string_to_id_bin(p.default_locale_id) or {
		return new_internal_error(error_id_invalid, 'default_locale_id')
	}

	default_region_id_bin := option_id_string_to_id_bin(p.default_region_id) or {
		return new_internal_error(error_id_invalid, 'default_region_id')
	}

	default_stock_location_id_bin := option_id_string_to_id_bin(p.default_stock_location_id) or {
		return new_internal_error(error_id_invalid, 'default_stock_location_id')
	}

	locale_ids_bin := option_array_id_string_to_array_id_bin(p.locale_ids) or {
		return new_internal_error(error_id_invalid, 'locale_id')
	}

	default_sales_channel_id_bin := option_id_string_to_id_bin(p.default_sales_channel_id) or {
		return new_internal_error(error_id_invalid, 'default_sales_channel_id')
	}

	return StoreRequestHygienised{
		name:                          p.name
		default_locale_id:             p.default_locale_id
		default_locale_id_bin:         default_locale_id_bin
		default_region_id:             p.default_region_id
		default_region_id_bin:         default_region_id_bin
		default_stock_location_id:     p.default_stock_location_id
		default_stock_location_id_bin: default_stock_location_id_bin
		default_sales_channel_id:      p.default_sales_channel_id
		default_sales_channel_id_bin:  default_sales_channel_id_bin
		locale_ids:                    p.locale_ids
		locale_ids_bin:                locale_ids_bin
		currency_codes:                p.currency_codes
	}
}

struct ImageTranslationRequestHygienised {
	locale_id     string
	locale_id_bin []u8
	alt           string
}

fn hygienise_image_translation_request(i ImageTranslationRequest) !ImageTranslationRequestHygienised {
	locale_id_bin := id_string_to_bin(i.locale_id) or {
		return new_internal_error(error_id_invalid, 'locale_id')
	}

	if i.alt == '' {
		return new_internal_error(error_empty_field, 'alt')
	}

	return ImageTranslationRequestHygienised{
		locale_id:     i.locale_id
		locale_id_bin: locale_id_bin
		alt:           i.alt
	}
}

struct ImageRequestHygienised {
	url string
mut:
	translations []ImageTranslationRequestHygienised
}

fn hygienise_image_request(p ImageRequest) !ImageRequestHygienised {
	mut image := ImageRequestHygienised{
		url: p.url
	}

	if translations := p.translations {
		mut itrh := []ImageTranslationRequestHygienised{len: translations.len}
		for i := 0; i < translations.len; i++ {
			itrh[i] = hygienise_image_translation_request(translations[i])!
		}
		image.translations = itrh
	}
	return image
}

struct ProductTranslationRequestHygienised {
	locale_id     string
	locale_id_bin []u8
	title         ?string
	subtitle      ?string
	description   ?string
}

fn hygienise_product_translation_request(p ProductTranslationRequest) !ProductTranslationRequestHygienised {
	locale_id_bin := id_string_to_bin(p.locale_id) or {
		return new_internal_error(error_id_invalid, 'locale_id')
	}

	return ProductTranslationRequestHygienised{
		locale_id:     p.locale_id
		locale_id_bin: locale_id_bin
		title:         p.title
		subtitle:      p.subtitle
		description:   p.description
	}
}

struct ProductOptionTranslationRequestHygienised {
	title         string
	locale_id     string
	locale_id_bin []u8
}

fn hygienise_product_option_translation_request(p ProductOptionTranslationRequest) !ProductOptionTranslationRequestHygienised {
	locale_id_bin := id_string_to_bin(p.locale_id) or {
		return new_internal_error(error_id_invalid, 'locale_id')
	}
	return ProductOptionTranslationRequestHygienised{
		title:         p.title
		locale_id:     p.locale_id
		locale_id_bin: locale_id_bin
	}
}

struct ProductOptionValueTranslationRequestHygienised {
	locale_id     string
	locale_id_bin []u8
	name          string
}

fn hygienise_product_option_value_translation_request(p ProductOptionValueTranslationRequest) !ProductOptionValueTranslationRequestHygienised {
	locale_id_bin := id_string_to_bin(p.locale_id) or {
		return new_internal_error(error_id_invalid, 'locale_id')
	}

	return ProductOptionValueTranslationRequestHygienised{
		locale_id:     p.locale_id
		locale_id_bin: locale_id_bin
		name:          p.name
	}
}

struct ProductOptionValueRequestHygienised {
	translations []ProductOptionValueTranslationRequestHygienised
}

fn hygienise_product_option_value_request(p ProductOptionValueRequest) !ProductOptionValueRequestHygienised {
	mut translations := []ProductOptionValueTranslationRequestHygienised{len: p.translations.len}
	for i := 0; i < p.translations.len; i++ {
		translations[i] = hygienise_product_option_value_translation_request(p.translations[i])!
	}

	return ProductOptionValueRequestHygienised{
		translations: translations
	}
}

struct ProductOptionCreateRequestHygienised {
	translations []ProductOptionTranslationRequestHygienised
	values       []ProductOptionValueRequestHygienised
}

fn hygienise_product_option_request(p ProductOptionCreateRequest) !ProductOptionCreateRequestHygienised {
	mut translations := []ProductOptionTranslationRequestHygienised{len: p.translations.len}
	for i := 0; i < p.translations.len; i++ {
		translations[i] = hygienise_product_option_translation_request(p.translations[i])!
	}

	mut values := []ProductOptionValueRequestHygienised{len: p.values.len}
	for i := 0; i < p.translations.len; i++ {
		values[i] = hygienise_product_option_value_request(p.values[i])!
	}

	return ProductOptionCreateRequestHygienised{
		translations: translations
		values:       values
	}
}

struct ProductOptionUpdateRequestHygienised {
	translations []ProductOptionTranslationRequestHygienised
}

fn hygienise_product_option_update_request(p ProductOptionUpdateRequest) !ProductOptionUpdateRequestHygienised {
	mut translations := []ProductOptionTranslationRequestHygienised{len: p.translations.len}
	for i := 0; i < p.translations.len; i++ {
		translations[i] = hygienise_product_option_translation_request(p.translations[i])!
	}

	return ProductOptionUpdateRequestHygienised{
		translations: translations
	}
}

struct MoneyAmountRequestHygienised {
	amount        i32
	region_id     ?string
	region_id_bin []u8
	currency_code string
	max_quantity  ?i32
	min_quantity  ?i32
}

fn hygienise_money_amount_request(p MoneyAmountRequest) !MoneyAmountRequestHygienised {
	region_id_bin := option_id_string_to_id_bin(p.region_id) or {
		return new_internal_error(error_id_invalid, 'region_id')
	}

	return MoneyAmountRequestHygienised{
		amount:        p.amount
		region_id:     p.region_id
		region_id_bin: region_id_bin
		currency_code: p.currency_code
		max_quantity:  p.max_quantity
		min_quantity:  p.min_quantity
	}
}

// Because option ids cannot be provided during product creation, as they have yet to be created, variants
// cannot be created at the same time as a product is created.
// This can be handled by the frontend application in a non-atomic way, as these operations happen sequentially
// outside of a database transaction.
struct ProductVariantRequestHygienised {
	title                ?string
	ean                  ?string
	upc                  ?string
	barcode              ?string
	variant_rank         ?i32
	inventory_item       ?InventoryItemRequest
	option_value_ids     ?[]string
	option_value_ids_bin [][]u8
	metadata             ?string
mut:
	money_amounts ?[]MoneyAmountRequestHygienised
}

fn hygienise_product_variant_request(p ProductVariantRequest) !ProductVariantRequestHygienised {
	option_value_ids_bin := option_array_id_string_to_array_id_bin(p.option_value_ids) or {
		return new_internal_error(error_id_invalid, 'ids_bin')
	}

	mut ph := ProductVariantRequestHygienised{
		title:                p.title
		ean:                  p.ean
		upc:                  p.upc
		barcode:              p.barcode
		variant_rank:         p.variant_rank
		inventory_item:       p.inventory_item
		option_value_ids:     p.option_value_ids
		option_value_ids_bin: option_value_ids_bin
		metadata:             p.metadata
	}

	if money_amounts := p.money_amounts {
		mut h := []MoneyAmountRequestHygienised{len: money_amounts.len}
		for i := 0; i < money_amounts.len; i++ {
			h[i] = hygienise_money_amount_request(money_amounts[i])!
		}
		ph.money_amounts = h
	}

	return ph
}

struct ProductCategoryTranslationRequestHygienised {
	locale_id     string
	locale_id_bin []u8
	name          ?string
	description   ?string
}

struct ProductCategoryRequestHygienised {
	handle                 ?string
	is_internal            ?bool
	is_active              ?bool
	parent_category_id     ?string
	parent_category_id_bin []u8
	category_rank          ?i32
	metadata               ?string
mut:
	translations ?[]ProductCategoryTranslationRequestHygienised
}
