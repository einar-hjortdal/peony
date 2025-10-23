module peony

struct AuthRequest {
	email    string
	password string
}

struct StoreRequest {
	name                      ?string
	default_locale_id         ?string   @[json: 'defaultLocaleId']
	default_region_id         ?string   @[json: 'defaultRegionId']
	default_stock_location_id ?string   @[json: 'defaultStockLocationId']
	default_sales_channel_id  ?string   @[json: 'defaultSalesChannelId']
	locale_ids                ?[]string @[json: 'localeIds']
	currency_codes            ?[]string @[json: 'currencyCodes']
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

struct ImageRequest {
	url          string
	translations ?[]ImageTranslationRequest
}

struct UserCreateRequest {
	email      string
	password   string
	first_name ?string @[json: 'firstName']
	last_name  ?string @[json: 'lastName']
	role       ?string
	image      ?ImageRequest
	metadata   ?string @[raw]
}

struct UserUpdateRequest {
	email      ?string
	first_name ?string @[json: 'firstName']
	last_name  ?string @[json: 'lastName']
	role       ?string
	image      ?ImageRequest
	metadata   ?string @[raw]
}

struct ImageTranslationRequest {
	locale_id string @[json: 'localeId']
	alt       string
}

struct ProductTranslationRequest {
	locale_id   string @[json: 'localeId']
	title       ?string
	subtitle    ?string
	description ?string
}

struct ProductOptionValueTranslationRequest {
	locale_id string @[json: 'localeId']
	name      string
}

struct ProductOptionValueRequest {
	translations []ProductOptionValueTranslationRequest
}

struct ProductOptionTranslationRequest {
	title     string
	locale_id string @[json: 'localeId']
}

struct ProductOptionCreateRequest {
	translations []ProductOptionTranslationRequest
	values       []ProductOptionValueRequest
}

struct ProductOptionUpdateRequest {
	translations []ProductOptionTranslationRequest
}

// max_quantity the maximum quantity required to be added to the cart for the price to be used.
// min_quantity the minimum quantity required to be added to the cart for the price to be used.
struct MoneyAmountRequest {
	amount        i32
	region_id     string @[json: 'regionId']
	currency_code string @[json: 'currencyCode']
	max_quantity  ?i32   @[json: 'maxQuantity']
	min_quantity  ?i32   @[json: 'minQuantity']
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

struct ProductVariantRequest {
	title            ?string
	ean              ?string
	upc              ?string
	barcode          ?string
	variant_rank     ?i32                  @[json: 'variantRank']
	inventory_item   ?InventoryItemRequest @[json: 'inventoryItem']
	money_amounts    ?[]MoneyAmountRequest @[json: 'moneyAmounts']
	option_value_ids ?[]string             @[json: 'optionValues']
	metadata         ?string               @[raw]
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

struct NewCurrencyData {
	includes_tax bool @[json: 'includesTax']
}

struct InventoryLevelRequest {
	stocked_quantity i32 @[json: 'stockedQuantity']
}

struct ProductCategoryTranslationRequest {
	locale_id   string @[json: 'localeId']
	name        ?string
	description ?string
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

struct ProductCreateRequest {
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
	options           ?[]ProductOptionCreateRequest
	images            ?[]ImageRequest
}

struct ProductCreateRequestHygienised {
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
	options      ?[]ProductOptionCreateRequestHygienised
	translations ?[]ProductTranslationRequestHygienised
	images       ?[]ImageRequestHygienised
}

fn (p ProductCreateRequest) hygienise() !ProductCreateRequestHygienised {
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

	mut ph := ProductCreateRequestHygienised{
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

	if options := p.options {
		mut h := []ProductOptionCreateRequestHygienised{len: options.len}
		for i := 0; i < options.len; i++ {
			h[i] = hygienise_product_option_request(options[i])!
		}
		ph.options = h
	}

	if translations := p.translations {
		mut h := []ProductTranslationRequestHygienised{len: translations.len}
		for i := 0; i < translations.len; i++ {
			h[i] = hygienise_product_translation_request(translations[i])!
		}
		ph.translations = h
	}

	if images := p.images {
		mut h := []ImageRequestHygienised{}
		for i := 0; i < images.len; i++ {
			h[i] = hygienise_image_request(images[i])!
		}
		ph.images = h
	}

	return ph
}

struct ProductUpdateRequest {
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

struct ProductUpdateRequestHygienised {
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

fn (p ProductUpdateRequest) hygienise() !ProductUpdateRequestHygienised {
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

	mut ph := ProductUpdateRequestHygienised{
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
		mut h := []ProductTranslationRequestHygienised{len: translations.len}
		for i := 0; i < translations.len; i++ {
			h[i] = hygienise_product_translation_request(translations[i])!
		}
		ph.translations = h
	}

	if images := p.images {
		mut h := []ImageRequestHygienised{}
		for i := 0; i < images.len; i++ {
			h[i] = hygienise_image_request(images[i])!
		}
		ph.images = h
	}

	return ph
}
