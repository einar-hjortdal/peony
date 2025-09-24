module peony

struct AuthRequest {
	email    string
	password string
}

struct StoreRequest {
	name                      ?string
	default_locale_id         ?string @[json: 'defaultLocaleId']
	default_currency_code     ?string @[json: 'defaultCurrencyCode']
	default_stock_location_id ?string @[json: 'defaultStockLocationId']
	default_sales_channel_id  ?string @[json: 'defaultSalesChannelId']
	locale_ids                ?[]string
	currency_codes            ?[]string
}

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

struct SalesChannelRequest {
	name        string
	description ?string
	is_disabled ?bool @[json: 'isDisabled']
}

struct SalesChannelUpdateRequest {
	name        ?string
	description ?string
	is_disabled ?bool @[json: 'isDisabled']
}

struct NewUserData {
	email      string
	password   string
	first_name ?string @[json: 'firstName']
	last_name  ?string @[json: 'lastName']
	role       ?string
	metadata   ?string @[raw]
}

struct UpdateUserData {
	first_name ?string @[json: 'firstName']
	last_name  ?string @[json: 'lastName']
	role       ?string
	metadata   ?string @[raw]
}

struct ImageTranslationRequest {
	locale_id string @[json: 'localeId']
	alt       string
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

struct ImageRequest {
	url          string
	translations ?[]ImageTranslationRequest
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

struct ProductTranslationRequest {
	locale_id   string @[json: 'localeId']
	title       ?string
	subtitle    ?string
	description ?string
}

struct ProductTranslationRequestHygienised {
	locale_id     string
	locale_id_bin []u8
	title         ?string
	subtitle      ?string
	description   ?string
}

struct ProductRequest {
	handle            ?string
	is_giftcard       ?bool @[json: 'isGiftcard']
	status            ?string
	thumbnail         ?string
	type_id           ?string @[json: 'typeId']
	discountable      ?bool
	metadata          ?string   @[raw]
	tag_ids           ?[]string @[json: 'tagIds']
	sales_channel_ids ?[]string @[json: 'salesChannelIds']
	category_ids      ?[]string @[json: 'categoryIds']
	collection_ids    ?[]string @[json: 'collectionIds']
	translations      ?[]ProductTranslationRequest
	images            ?[]ImageRequest
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
			translation := translations[i]
			locale_id_bin := id_string_to_bin(translation.locale_id) or {
				return new_internal_error(error_id_invalid, 'locale_id')
			}
			pth[i] = ProductTranslationRequestHygienised{
				locale_id:     translation.locale_id
				locale_id_bin: locale_id_bin
				title:         translation.title
				subtitle:      translation.subtitle
				description:   translation.description
			}
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

// By default, taxes are automatically calculated by peony during checkout. This behavior can be disabled
// for a region to limit the requests being sent to a tax provider.
struct RegionCreateRequest {
	automatic_taxes ?bool
	country_codes   []string
	currency_code   string
	includes_tax    ?bool
	name            string
	// taxes
}

struct RegionUpdateRequest {
	automatic_taxes ?bool
	country_codes   ?[]string
	currency_code   ?string
	includes_tax    ?bool
	name            ?string
	//  taxes
}

// id: if provided, the existing price will be updated. otherwise, a new price will be created.
// currency_code: required if region_id is not provided, ignored when region_id or id is provided.
// region_id: required if currency_code is not provided, ignored when id is provided.
// max_quantity the maximum quantity required to be added to the cart for the price to be used.
// min_quantity the minimum quantity required to be added to the cart for the price to be used.
struct MoneyAmountRequest {
	amount        i32
	currency_code ?string @[json: 'currencyCode']
	id            ?string
	max_quantity  ?i32    @[json: 'maxQuantity']
	min_quantity  ?i32    @[json: 'minQuantity']
	region_id     ?string @[json: 'regionId']
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

struct ProductOptionTranslationData {
	title     string
	locale_id string @[json: 'localeId']
}

struct ProductOptionTranslationDataHygienised {
	title         string
	locale_id     string
	locale_id_bin []u8
}

struct ProductOptionRequest {
	translations []ProductOptionTranslationData
}

struct ProductOptionValueTranslationRequest {
	locale_id string @[json: 'localeId']
	name      string
}

struct ProductOptionValueTranslationRequestHygienised {
	locale_id     string
	locale_id_bin []u8
	name          string
}

struct ProductOptionValueRequest {
	option_id    string @[json: 'optionId']
	translations []ProductOptionValueTranslationRequest
}

struct ProductOptionValueRequestHygienised {
	option_id     string
	option_id_bin []u8
	translations  []ProductOptionValueTranslationRequestHygienised
}

struct ProductVariantRequest {
	title         ?string
	ean           ?string
	upc           ?string
	barcode       ?string
	variant_rank  ?i32                         @[json: 'variantRank']
	metadata      ?string                      @[raw]
	money_amounts ?[]MoneyAmountRequest        @[json: 'moneyAmounts']
	option_values ?[]ProductOptionValueRequest @[json: 'optionValues']
}

fn hygienise_product_option_value_request(povr ProductOptionValueRequest) !ProductOptionValueRequestHygienised {
	option_id_bin := id_string_to_bin(povr.option_id)!
	mut translations := []ProductOptionValueTranslationRequestHygienised{len: povr.translations.len}
	for i := 0; i < povr.translations.len; i++ {
		locale_id_bin := id_string_to_bin(povr.translations[i].locale_id)!
		translations[i] = ProductOptionValueTranslationRequestHygienised{
			locale_id:     povr.translations[i].locale_id
			locale_id_bin: locale_id_bin
			name:          povr.translations[i].name
		}
	}
	return ProductOptionValueRequestHygienised{
		option_id:     povr.option_id
		option_id_bin: option_id_bin
		translations:  translations
	}
}

struct NewCurrencyData {
	includes_tax bool @[json: 'includesTax']
}

struct InventoryItemRequest {
	sku               ?string
	origin_country    ?string @[json: 'originCountry']
	hs_code           ?string @[json: 'hsCode']
	mid_code          ?string @[json: 'midCode']
	material          ?string
	weight            ?i32
	length            ?i32
	height            ?i32
	width             ?i32
	requires_shipping ?bool @[json: 'requiresShipping']
	manage_inventory  ?bool @[json: 'manageInventory']
	allow_backorder   ?bool @[json: 'allowBackorder']
}

struct InventoryLevelRequest {
	stocked_quantity i32 @[json: 'stockedQuantity']
}

struct ProductCategoryTranslationRequest {
	locale_id   string @[json: 'localeId']
	name        ?string
	description ?string
}

struct ProductCategoryTranslationRequestHygienised {
	locale_id     string
	locale_id_bin []u8
	name          ?string
	description   ?string
}

struct ProductCategoryRequest {
	handle             ?string
	is_internal        ?bool   @[json: 'isInternal']
	is_active          ?bool   @[json: 'isActive']
	parent_category_id ?string @[json: 'parentCategoryId']
	category_rank      ?i32    @[json: 'categoryRank']
	metadata           ?string @[raw]
	translations       ?[]ProductCategoryTranslationRequest
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
