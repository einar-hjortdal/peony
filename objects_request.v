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
	translations      ?[]UpdateProductTranslationData
}

struct UpdateProductTranslationData {
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
	translations ?[]ProductOptionTranslationData
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
