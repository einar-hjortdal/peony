module peony

struct AuthRequest {
	email    string
	password string
}

struct NewStoreData {
	name                  ?string
	default_locale_id     ?string @[json: 'defaultLocaleId']
	default_currency_code ?string @[json: 'defaultCurrencyCode']
	locales               ?[]string
	currencies            ?[]string
}

struct NewUserData {
	email      string
	password   string
	first_name ?string @[json: 'firstName']
	last_name  ?string @[json: 'lastName']
	role       ?string
}

struct UpdateUserData {
	first_name ?string @[json: 'firstName']
	last_name  ?string @[json: 'lastName']
	role       ?string
}

struct ProductTranslationData {
	locale_id   string @[json: 'localeId']
	title       ?string
	subtitle    ?string
	description ?string
}

struct ProductOptionTranslationData {
	title     string
	locale_id string @[json: 'localeId']
}

struct ProductOptionData {
	id           ?string
	translations []ProductOptionTranslationData
}

struct ProductData {
	handle            ?string
	is_giftcard       ?bool @[json: 'isGiftcard']
	status            ?string
	thumbnail         ?string
	collection_id     ?string @[json: 'collectionId']
	type_id           ?string @[json: 'typeId']
	discountable      ?bool
	images            ?[]string
	tag_ids           ?[]string @[json: 'tagIds']
	sales_channel_ids ?[]string @[json: 'salesChannelIds']
	category_ids      ?[]string @[json: 'categoryIds']
	translations      ?[]ProductTranslationData
	options           ?[]ProductOptionData
}

// By default, taxes are automatically calculated by peony during checkout. This behavior can be disabled
// for a region to limit the requests being sent to a tax provider.
struct RegionRequest {
	automatic_taxes ?bool
	country_codes   []string
	currency_code   string
	includes_tax    ?bool
	name            string
	rate_id         string
}

struct RegionRequestHygienised {
	automatic_taxes ?bool
	country_codes   []string
	currency_code   string
	includes_tax    ?bool
	name            string
	rate_id         string
	rate_id_bin     []u8
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

struct ProductOptionValueTranslationRequest {
	title     string
	locale_id string @[json: 'localeId']
}

struct ProductOptionValueRequest {
	option_id    string @[json: 'optionId']
	translations []ProductOptionValueTranslationRequest
}

struct ProductVariantRequest {
	title              ?string
	sku                ?string
	ean                ?string
	upc                ?string
	barcode            ?string
	hs_code            ?string @[json: 'hsCode']
	variant_rank       ?i32    @[json: 'variantRank']
	inventory_quantity ?i32    @[json: 'inventoryQuantity']
	allow_backorder    ?bool   @[json: 'allowBackorder']
	manage_inventory   ?bool   @[json: 'manageInventory']
	origin_country     ?string @[json: 'originCountry']
	mid_code           ?string @[json: 'midCode']
	weight             ?i32
	length             ?i32
	height             ?i32
	width              ?i32
	money_amounts      ?[]MoneyAmountRequest @[json: 'moneyAmounts']
	options            ?[]ProductOptionValueRequest
}

struct NewCurrencyData {
	includes_tax bool @[json: 'includesTax']
}
