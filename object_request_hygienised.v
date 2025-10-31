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

fn (i ImageTranslationRequest) hygienise() !ImageTranslationRequestHygienised {
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
	translations ?[]ImageTranslationRequestHygienised
}

fn (p ImageRequest) hygienise() !ImageRequestHygienised {
	mut image := ImageRequestHygienised{
		url: p.url
	}

	if translations := p.translations {
		mut itrh := []ImageTranslationRequestHygienised{len: translations.len}
		for i := 0; i < translations.len; i++ {
			itrh[i] = translations[i].hygienise()!
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

fn (p ProductOptionTranslationRequest) hygienise() !ProductOptionTranslationRequestHygienised {
	locale_id_bin := id_string_to_bin(p.locale_id) or {
		return new_internal_error(error_id_invalid, 'locale_id')
	}
	return ProductOptionTranslationRequestHygienised{
		title:         p.title
		locale_id:     p.locale_id
		locale_id_bin: locale_id_bin
	}
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
