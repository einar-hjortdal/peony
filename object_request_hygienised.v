module peony

struct StoreRequestHygienised {
	name                          ?string
	default_locale_id             ?string
	default_locale_id_bin         []u8
	default_currency_code         ?string
	default_stock_location_id     ?string
	default_stock_location_id_bin []u8
	default_sales_channel_id      ?string
	default_sales_channel_id_bin  []u8
	locale_ids                    ?[]string
	locale_ids_bin                [][]u8
	currency_codes                ?[]string
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

struct ProductRequestHygienised {
	handle                ?string
	is_giftcard           ?bool
	status                ?string
	thumbnail             ?string
	type_id               ?string
	type_id_bin           []u8
	discountable          ?bool
	metadata              ?string
	tag_ids               ?[]string
	tag_ids_bin           [][]u8
	sales_channel_ids     ?[]string
	sales_channel_ids_bin [][]u8
	category_ids          ?[]string
	category_ids_bin      [][]u8
	collection_ids        ?[]string
	collection_ids_bin    [][]u8
mut:
	translations ?[]ProductTranslationRequestHygienised
	images       ?[]ImageRequestHygienised
}

fn hygienise_product_request(p ProductRequest) !ProductRequestHygienised {
	type_id_bin := option_id_string_to_id_bin(p.type_id) or {
		return new_internal_error(error_id_invalid, 'type_id')
	}

	tag_ids_bin := option_array_id_string_to_array_id_bin(p.tag_ids) or {
		return new_internal_error(error_id_invalid, 'tag_id')
	}

	sales_channel_ids_bin := option_array_id_string_to_array_id_bin(p.sales_channel_ids) or {
		return new_internal_error(error_id_invalid, 'sales_channel_id')
	}

	category_ids_bin := option_array_id_string_to_array_id_bin(p.category_ids) or {
		return new_internal_error(error_id_invalid, 'category_id')
	}

	collection_id_bin := option_array_id_string_to_array_id_bin(p.collection_ids) or {
		return new_internal_error(error_id_invalid, 'collection_id')
	}

	mut ph := ProductRequestHygienised{
		handle:                p.handle
		is_giftcard:           p.is_giftcard
		status:                p.status
		thumbnail:             p.thumbnail
		type_id:               p.type_id
		type_id_bin:           type_id_bin
		discountable:          p.discountable
		metadata:              p.metadata
		tag_ids:               p.tag_ids
		tag_ids_bin:           tag_ids_bin
		sales_channel_ids:     p.sales_channel_ids
		sales_channel_ids_bin: sales_channel_ids_bin
		category_ids:          p.category_ids
		category_ids_bin:      category_ids_bin
		collection_ids:        p.collection_ids
		collection_ids_bin:    collection_id_bin
	}

	if translations := p.translations {
		mut pth := []ProductTranslationRequestHygienised{len: translations.len}
		for i := 0; i < translations.len; i++ {
			pth[i] = hygienise_product_translation_request(translations[i])!
		}
		ph.translations = pth
	}

	if images := p.images {
		mut irh := []ImageRequestHygienised{len: images.len}
		for i := 0; i < images.len; i++ {
			irh[i] = hygienise_image_request(images[i])!
		}
		ph.images = irh
	}

	return ph
}

struct MoneyAmountRequestHygienised {
	amount        i32
	currency_code ?string
	id            ?string
	id_bin        []u8
	max_quantity  ?i32
	min_quantity  ?i32
	region_id     ?string
	region_id_bin []u8
}

struct ProductOptionTranslationDataHygienised {
	title         string
	locale_id     string
	locale_id_bin []u8
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
	option_id     string
	option_id_bin []u8
	translations  []ProductOptionValueTranslationRequestHygienised
}

fn hygienise_product_option_value_request(povr ProductOptionValueRequest) !ProductOptionValueRequestHygienised {
	option_id_bin := id_string_to_bin(povr.option_id) or {
		return new_internal_error(error_id_invalid, 'option_id')
	}

	mut translations := []ProductOptionValueTranslationRequestHygienised{len: povr.translations.len}
	for i := 0; i < povr.translations.len; i++ {
		translations[i] = hygienise_product_option_value_translation_request(povr.translations[i])!
	}

	return ProductOptionValueRequestHygienised{
		option_id:     povr.option_id
		option_id_bin: option_id_bin
		translations:  translations
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
