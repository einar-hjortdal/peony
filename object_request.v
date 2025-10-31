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

struct ProductOptionValueTranslationRequestHygienised {
	locale_id     string
	locale_id_bin []u8
	name          string
}

fn (p ProductOptionValueTranslationRequest) hygienise() !ProductOptionValueTranslationRequestHygienised {
	locale_id_bin := id_string_to_bin(p.locale_id) or {
		return new_internal_error(error_id_invalid, 'locale_id')
	}

	return ProductOptionValueTranslationRequestHygienised{
		locale_id:     p.locale_id
		locale_id_bin: locale_id_bin
		name:          p.name
	}
}

struct ProductOptionValueRequest {
	translations []ProductOptionValueTranslationRequest
}

struct ProductOptionValueRequestHygienised {
	translations []ProductOptionValueTranslationRequestHygienised
}

fn (p ProductOptionValueRequest) hygienise() !ProductOptionValueRequestHygienised {
	mut translations := []ProductOptionValueTranslationRequestHygienised{len: p.translations.len}
	for i := 0; i < p.translations.len; i++ {
		translations[i] = p.translations[i].hygienise()!
	}

	return ProductOptionValueRequestHygienised{
		translations: translations
	}
}

// verifies:
// TODO all locale_id exist
// The product_option_value has the default translation
fn (p ProductOptionValueRequestHygienised) verify(default_locale_id_bin []u8) ! {
	option_value_translations := p.translations

	if option_value_translations.len == 0 {
		return new_internal_error(error_missing_default_translation, 'The product_option_value lacks translations, at least one translation in the default locale must be provided.')
	}

	mut found := false
	for i := 0; i < option_value_translations.len; i++ {
		translation := option_value_translations[i]
		if translation.locale_id_bin == default_locale_id_bin {
			found = true
		}
	}
	if found == false {
		return new_internal_error(error_missing_default_translation, 'The product_option_value lacks a translation in the default_locale_id')
	}
}

struct ProductOptionTranslationRequest {
	title     string
	locale_id string @[json: 'localeId']
}

struct ProductOptionCreateRequest {
	translations []ProductOptionTranslationRequest
	values       []ProductOptionValueRequest
}

struct ProductOptionCreateRequestHygienised {
	translations []ProductOptionTranslationRequestHygienised
	values       []ProductOptionValueRequestHygienised
}

fn (p ProductOptionCreateRequest) hygienise() !ProductOptionCreateRequestHygienised {
	mut translations := []ProductOptionTranslationRequestHygienised{len: p.translations.len}
	for i := 0; i < p.translations.len; i++ {
		translations[i] = p.translations[i].hygienise()!
	}

	mut values := []ProductOptionValueRequestHygienised{len: p.values.len}
	for i := 0; i < p.values.len; i++ {
		values[i] = p.values[i].hygienise()!
	}

	return ProductOptionCreateRequestHygienised{
		translations: translations
		values:       values
	}
}

// verifies:
// All locale_id exist TODO
// The product_option has the default translation
// The product_option has at least one value
// Each value has the default translation
fn (ph ProductOptionCreateRequestHygienised) verify(default_locale_id_bin []u8) ! {
	option_translations := ph.translations
	option_values := ph.values

	if option_translations.len == 0 {
		return new_internal_error(error_missing_default_translation, 'The product_option lacks translations, at least one translation in the default locale must be provided.')
	}

	if option_values.len == 0 {
		return new_internal_error(error_missing_default_translation, 'The product_option lacks values, at leat one value must be provided.')
	}

	mut found := false
	for i := 0; i < option_translations.len; i++ {
		translation := option_translations[i]
		if translation.locale_id_bin == default_locale_id_bin {
			found = true
		}
	}
	if found == false {
		return new_internal_error(error_missing_default_translation, 'The product_option lacks a translation in the default_locale_id')
	}

	for i := 0; i < option_values.len; i++ {
		option_values[i].verify(default_locale_id_bin)!
	}
}

struct ProductOptionUpdateRequest {
	translations []ProductOptionTranslationRequest
}

struct ProductOptionUpdateRequestHygienised {
	translations []ProductOptionTranslationRequestHygienised
}

fn (p ProductOptionUpdateRequest) hygienise() !ProductOptionUpdateRequestHygienised {
	mut translations := []ProductOptionTranslationRequestHygienised{len: p.translations.len}
	for i := 0; i < p.translations.len; i++ {
		translations[i] = p.translations[i].hygienise()!
	}

	return ProductOptionUpdateRequestHygienised{
		translations: translations
	}
}

// verifies:
// All locale_id exist TODO
// The product_option has the default translation
fn (ph ProductOptionUpdateRequestHygienised) verify(default_locale_id_bin []u8) ! {
	option_translations := ph.translations

	if option_translations.len == 0 {
		return new_internal_error(error_missing_default_translation, 'The product_option lacks translations, at least one translation in the default locale must be provided.')
	}

	mut found := false
	for i := 0; i < option_translations.len; i++ {
		translation := option_translations[i]
		if translation.locale_id_bin == default_locale_id_bin {
			found = true
		}
	}
	if found == false {
		return new_internal_error(error_missing_default_translation, 'a product_option lacks a translation in the default_locale_id')
	}
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

struct MoneyAmountRequestHygienised {
	amount        i32
	region_id     ?string
	region_id_bin []u8
	currency_code string
	max_quantity  ?i32
	min_quantity  ?i32
}

fn (p MoneyAmountRequest) hygienise() !MoneyAmountRequestHygienised {
	region_id_bin := option_id_string_to_id_bin(p.region_id) or {
		return new_internal_error(error_id_invalid, 'region_id')
	}

	return MoneyAmountRequestHygienised{
		amount:        p.amount
		region_id:     p.region_id
		region_id_bin: region_id_bin
		currency_code: p.currency_code
		max_quantity:  p.max_quantity
		min_quantity:  p.min_quantity
	}
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

// Because option ids cannot be provided during product creation, as they have yet to be created, variants
// cannot be created at the same time as a product is created.
// This can be handled by the frontend application in a non-atomic way.
struct ProductVariantRequest {
	title            ?string
	ean              ?string
	upc              ?string
	barcode          ?string
	variant_rank     ?i32                  @[json: 'variantRank']
	inventory_item   ?InventoryItemRequest @[json: 'inventoryItem']
	money_amounts    ?[]MoneyAmountRequest @[json: 'moneyAmounts']
	option_value_ids ?[]string             @[json: 'optionValueIds']
	metadata         ?string               @[raw]
}

struct ProductVariantRequestHygienised {
	title                ?string
	ean                  ?string
	upc                  ?string
	barcode              ?string
	variant_rank         ?i32
	inventory_item       ?InventoryItemRequest
	option_value_ids     ?[]string
	option_value_ids_bin [][]u8
	metadata             ?string
mut:
	money_amounts ?[]MoneyAmountRequestHygienised
}

fn (p ProductVariantRequest) hygienise() !ProductVariantRequestHygienised {
	option_value_ids_bin := option_array_id_string_to_array_id_bin(p.option_value_ids) or {
		return new_internal_error(error_id_invalid, 'ids_bin')
	}

	mut ph := ProductVariantRequestHygienised{
		title:                p.title
		ean:                  p.ean
		upc:                  p.upc
		barcode:              p.barcode
		variant_rank:         p.variant_rank
		inventory_item:       p.inventory_item
		option_value_ids:     p.option_value_ids
		option_value_ids_bin: option_value_ids_bin
		metadata:             p.metadata
	}

	if money_amounts := p.money_amounts {
		mut h := []MoneyAmountRequestHygienised{len: money_amounts.len}
		for i := 0; i < money_amounts.len; i++ {
			h[i] = money_amounts[i].hygienise()!
		}
		ph.money_amounts = h
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
			h[i] = options[i].hygienise()!
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
		mut h := []ImageRequestHygienised{len: images.len}
		for i := 0; i < images.len; i++ {
			h[i] = images[i].hygienise()!
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
			h[i] = images[i].hygienise()!
		}
		ph.images = h
	}

	return ph
}
