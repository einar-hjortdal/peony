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

struct ProductOptionRequest {
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
