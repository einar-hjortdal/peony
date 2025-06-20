module main

struct AuthRequest {
	email    string
	password string
}

struct NewStoreData {
	name                  ?string
	default_locale_code   ?string @[json: 'defaultLocaleCode']
	default_currency_code ?string @[json: 'defaultCurrencyCode']
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
