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

struct NewSalesChannelData {
	name        string
	description string @[omitempty]
	is_disabled bool   @[json: 'isDisabled'; omitempty]
}

struct NewUserData {
	email      string
	password   string
	first_name ?string @[json: 'firstName']
	last_name  ?string @[json: 'lastName']
	role       ?string
	metadata   ?string
}

struct UpdateUserData {
	first_name ?string @[json: 'firstName']
	last_name  ?string @[json: 'lastName']
	role       ?string
	metadata   ?string
}

struct ProductTranslationData {
	locale_id   string @[json: 'localeId']
	title       ?string
	subtitle    ?string
	description ?string
}

struct ProductData {
	handle            ?string
	is_giftcard       ?bool @[json: 'isGiftcard']
	status            ?string
	thumbnail         ?string
	collection_id     ?string @[json: 'collectionId']
	type_id           ?string @[json: 'typeId']
	discountable      ?bool
	metadata          ?string
	images            ?[]string
	tag_ids           ?[]string @[json: 'tagIds']
	sales_channel_ids ?[]string @[json: 'salesChannelIds']
	category_ids      ?[]string @[json: 'categoryIds']
	translations      ?[]ProductTranslationData
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
	title            ?string
	sku              ?string
	ean              ?string
	upc              ?string
	barcode          ?string
	hs_code          ?string @[json: 'hsCode']
	variant_rank     ?i32    @[json: 'variantRank']
	allow_backorder  ?bool   @[json: 'allowBackorder']
	manage_inventory ?bool   @[json: 'manageInventory']
	origin_country   ?string @[json: 'originCountry']
	mid_code         ?string @[json: 'midCode']
	material         ?string
	weight           ?i32
	length           ?i32
	height           ?i32
	width            ?i32
	metadata         ?string
	money_amounts    ?[]MoneyAmountRequest        @[json: 'moneyAmounts']
	option_values    ?[]ProductOptionValueRequest @[json: 'optionValues']
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
	requires_shipping ?bool @[json: 'requiresShipping']
}

struct InventoryLevelRequest {
	stocked_quantity ?i32 @[json: 'stockedQuantity']
}
