module main

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

struct ProductOptionValueTranslationRequest {
	title     string
	locale_id string @[json: 'localeId']
}

struct ProductOptionValueRequest {
	option_id    string @[json: 'optionId']
	translations []ProductOptionValueTranslationRequest
}

struct VariantRequest {
	title ?string
	// prices             ?[]Price
	options            ?[]ProductOptionValueRequest
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
}

struct UpdateMoneyAmountData {
	id            ?string
	currency_code string @[json: 'currencyCode']
	amount        i32
	min_quantity  ?i32    @[json: 'minQuantity']
	max_quantity  ?i32    @[json: 'maxQuantity']
	price_list_id ?string @[json: 'priceListId']
	region_id     ?string @[json: 'regionId']
	variant_id    ?string @[json: 'variantId']
}

struct RetrieveCurrenciesParams {
	code         ZeroArrayString
	includes_tax ZeroBool
	offset       ZeroI32
	fetch        ZeroI32
	order        ZeroString
}

fn extract_retrieve_currencies_params(m map[string]string) RetrieveCurrenciesParams {
	return RetrieveCurrenciesParams{
		code:         zero_array_string(m, 'code')
		includes_tax: zero_bool(m, 'includes_tax')
		offset:       zero_i32(m, 'offset')
		fetch:        zero_i32(m, 'fetch')
		order:        zero_string(m, 'order')
	}
}

struct RetrieveLocalesParams {
	offset ZeroI32
	fetch  ZeroI32
	order  ZeroString
}

fn extract_retrieve_locales_params(m map[string]string) RetrieveLocalesParams {
	return RetrieveLocalesParams{
		offset: zero_i32(m, 'offset')
		fetch:  zero_i32(m, 'fetch')
		order:  zero_string(m, 'order')
	}
}

struct NewCurrencyData {
	includes_tax bool @[json: 'includesTax']
}
