module main

import time

struct PeonySuccess {
	success bool
}

fn new_peony_success() PeonySuccess {
	return PeonySuccess{
		success: true
	}
}

struct PeonyError {
	Error
	message string
	details string
}

fn new_peony_error(message string, details string) PeonyError {
	return PeonyError{
		message: message
		details: details
	}
}

fn login_error() (string, string) {
	return 'Invalid email or password', 'No further details'
}

// count is the number of items in the database
// offset is the number of items skipped
// fetch is the number of items requested
struct ListResponse[T] {
	items  []T
	count  i64
	offset i32
	fetch  i32
}

struct UserResponse {
	id         string
	handle     string
	email      string
	role       string
	created_at time.Time @[json: 'createdAt']
	updated_at time.Time @[json: 'updatedAt']
	deleted_at time.Time @[json: 'deletedAt'; omitempty]
	first_name string    @[json: 'firstName'; omitempty]
	last_name  string    @[json: 'lastName'; omitempty]
}

fn format_user_response(u User) UserResponse {
	return UserResponse{
		id:         u.id
		handle:     u.handle
		email:      u.email
		role:       u.role
		created_at: u.created_at.Time
		updated_at: u.updated_at.Time
		deleted_at: u.deleted_at.Time
		first_name: u.first_name
		last_name:  u.last_name
	}
}

struct LocaleResponse {
	id   string
	code string
}

fn format_locale_response(l Locale) LocaleResponse {
	return LocaleResponse{
		id:   l.id
		code: l.code
	}
}

struct CurrencyResponse {
	code         string
	includes_tax bool @[json: 'includesTax']
}

fn format_currency_response(c Currency) CurrencyResponse {
	return CurrencyResponse{
		code:         c.code
		includes_tax: c.includes_tax
	}
}

struct StoreResponse {
	id                        string
	created_at                time.Time @[json: 'createdAt']
	updated_at                time.Time @[json: 'updatedAt']
	name                      string
	default_locale_code       string @[json: 'defaultLocaleCode']
	default_currency_code     string @[json: 'defaultCurrencyCode']
	default_stock_location_id string @[json: 'defaultStockLocationId'; omitempty]
	default_sales_channel_id  string @[json: 'defaultSalesChannelId'; omitempty]
	locales                   []LocaleResponse
	currencies                []CurrencyResponse
}

fn format_store_response(s Store) StoreResponse {
	mut locales := []LocaleResponse{len: s.locales.len}
	for i := 0; i < s.locales.len; i++ {
		locales[i] = format_locale_response(s.locales[i])
	}

	mut currencies := []CurrencyResponse{len: s.currencies.len}
	for i := 0; i < s.currencies.len; i++ {
		currencies[i] = format_currency_response(s.currencies[i])
	}

	return StoreResponse{
		id:                        s.id
		created_at:                s.created_at.Time
		updated_at:                s.updated_at.Time
		name:                      s.name
		default_locale_code:       s.default_locale_code
		default_currency_code:     s.default_currency_code
		default_stock_location_id: s.default_stock_location_id
		default_sales_channel_id:  s.default_sales_channel_id
		locales:                   locales
		currencies:                currencies
	}
}

struct ImageResponse {
	id         string
	created_at time.Time @[json: 'createdAt']
	updated_at time.Time @[json: 'updatedAt']
	deleted_at time.Time @[json: 'deletedAt'; omitempty]
	url        string
}

fn format_image_response(i Image) ImageResponse {
	return ImageResponse{
		id:         i.id
		created_at: i.created_at.Time
		updated_at: i.updated_at.Time
		deleted_at: i.deleted_at.Time
		url:        i.url
	}
}

struct ProductTranslationResponse {
	product_id  string    @[json: 'productId']
	locale_code string    @[json: 'localeCode']
	created_at  time.Time @[json: 'createdAt']
	updated_at  time.Time @[json: 'updatedAt']
	deleted_at  time.Time @[json: 'deletedAt'; omitempty]
	title       string    @[omitempty]
	subtitle    string    @[omitempty]
	description string    @[omitempty]
}

fn format_product_translation_response(p ProductTranslation) ProductTranslationResponse {
	return ProductTranslationResponse{
		product_id:  p.product_id
		locale_code: p.locale_code
		created_at:  p.created_at.Time
		updated_at:  p.updated_at.Time
		deleted_at:  p.deleted_at.Time
		title:       p.title
		subtitle:    p.subtitle
		description: p.description
	}
}

struct ProductOptionValueTranslationResponse {
	product_option_value_id string @[json: 'productOptionValueId']
	locale_code             string @[json: 'localeCode']
	name                    string
}

fn format_product_option_value_translation_response(p ProductOptionValueTranslation) ProductOptionValueTranslationResponse {
	return ProductOptionValueTranslationResponse{
		product_option_value_id: p.product_option_value_id
		locale_code:             p.locale_code
		name:                    p.name
	}
}

struct ProductOptionValueResponse {
	id           string
	created_at   time.Time @[json: 'createdAt']
	updated_at   time.Time @[json: 'updatedAt']
	deleted_at   time.Time @[json: 'deletedAt'; omitempty]
	option_id    string    @[json: 'optionId']
	variant_id   string    @[json: 'variantId']
	translations []ProductOptionValueTranslationResponse
}

fn format_product_option_value_response(p ProductOptionValue) ProductOptionValueResponse {
	mut translations := []ProductOptionValueTranslationResponse{len: p.translations.len}
	for i := 0; i < p.translations.len; i++ {
		translations[i] = format_product_option_value_translation_response(p.translations[i])
	}

	return ProductOptionValueResponse{
		id:           p.id
		created_at:   p.created_at.Time
		updated_at:   p.updated_at.Time
		deleted_at:   p.deleted_at.Time
		option_id:    p.option_id
		variant_id:   p.variant_id
		translations: translations
	}
}

struct ProductOptionTranslationResponse {
	product_option_id string @[json: 'productOptionId']
	locale_code       string @[json: 'localeCode']
	title             string
}

fn format_product_option_translation_response(p ProductOptionTranslation) ProductOptionTranslationResponse {
	return ProductOptionTranslationResponse{
		product_option_id: p.product_option_id
		locale_code:       p.locale_code
		title:             p.title
	}
}

struct ProductOptionResponse {
	id           string
	created_at   time.Time @[json: 'createdAt']
	updated_at   time.Time @[json: 'updatedAt']
	deleted_at   time.Time @[json: 'deletedAt'; omitempty]
	product_id   string    @[json: 'productId']
	values       []ProductOptionValueResponse
	translations []ProductOptionTranslationResponse
}

fn format_product_option_response(p ProductOption) ProductOptionResponse {
	mut values := []ProductOptionValueResponse{len: p.values.len}
	for i := 0; i < p.values.len; i++ {
		values[i] = format_product_option_value_response(p.values[i])
	}

	mut translations := []ProductOptionTranslationResponse{len: p.translations.len}
	for i := 0; i < p.translations.len; i++ {
		translations[i] = format_product_option_translation_response(p.translations[i])
	}

	return ProductOptionResponse{
		id:           p.id
		created_at:   p.created_at.Time
		updated_at:   p.updated_at.Time
		deleted_at:   p.deleted_at.Time
		product_id:   p.product_id
		values:       values
		translations: translations
	}
}

struct MoneyAmountResponse {
	id            string
	created_at    time.Time @[json: 'createdAt']
	updated_at    time.Time @[json: 'updatedAt']
	deleted_at    time.Time @[json: 'deletedAt'; omitempty]
	currency_code string    @[json: 'currencyCode']
	amount        i32
	min_quantity  i32    @[json: 'minQuantity'; omitempty]
	max_quantity  i32    @[json: 'maxQuantity'; omitempty]
	price_list_id string @[json: 'priceListId'; omitempty]
	region_id     string @[json: 'regionId'; omitempty]
	variant_id    string @[json: 'variantId'; omitempty]
}

fn format_money_amount_response(m MoneyAmount) MoneyAmountResponse {
	return MoneyAmountResponse{
		id:            m.id
		created_at:    m.created_at.Time
		updated_at:    m.updated_at.Time
		deleted_at:    m.deleted_at.Time
		currency_code: m.currency_code
		amount:        m.amount
		min_quantity:  m.min_quantity
		max_quantity:  m.max_quantity
		price_list_id: m.price_list_id
		region_id:     m.region_id
		variant_id:    m.variant_id
	}
}

struct VariantResponse {
	id                 string
	created_at         time.Time @[json: 'createdAt']
	updated_at         time.Time @[json: 'updatedAt']
	deleted_at         time.Time @[json: 'deletedAt'; omitempty]
	product_id         string    @[json: 'productId']
	sku                string    @[omitempty]
	barcode            string    @[omitempty]
	ean                string    @[omitempty]
	upc                string    @[omitempty]
	variant_rank       i32       @[json: 'variantRank']
	inventory_quantity i32       @[json: 'inventoryQuantity']
	allow_backorder    bool      @[json: 'allowBackorder']
	manage_inventory   bool      @[json: 'manageInventory']
	hs_code            string    @[json: 'hsCode'; omitempty]
	origin_country     string    @[json: 'originCountry'; omitempty]
	mid_code           string    @[json: 'midCode'; omitempty]
	weight             i32       @[omitempty]
	length             i32       @[omitempty]
	height             i32       @[omitempty]
	width              i32       @[omitempty]
	title              string
	// image              string @[omitempty] // from variant_image TODO
	money_amounts []MoneyAmountResponse        @[json: 'moneyAmounts'; omitempty]
	option_values []ProductOptionValueResponse @[json: 'optionValues'; omitempty]
}

fn format_variant_response(v Variant) VariantResponse {
	mut option_values := []ProductOptionValueResponse{len: v.option_values.len}
	for i := 0; i < v.option_values.len; i++ {
		option_values[i] = format_product_option_value_response(v.option_values[i])
	}

	mut money_amounts := []MoneyAmountResponse{len: v.money_amounts.len}
	for i := 0; i < v.money_amounts.len; i++ {
		money_amounts[i] = format_money_amount_response(v.money_amounts[i])
	}

	return VariantResponse{
		id:                 v.id
		created_at:         v.created_at.Time
		updated_at:         v.updated_at.Time
		deleted_at:         v.deleted_at.Time
		product_id:         v.product_id
		sku:                v.sku
		barcode:            v.barcode
		ean:                v.ean
		upc:                v.upc
		variant_rank:       v.variant_rank
		inventory_quantity: v.inventory_quantity
		allow_backorder:    v.allow_backorder
		manage_inventory:   v.manage_inventory
		hs_code:            v.hs_code
		origin_country:     v.origin_country
		mid_code:           v.mid_code
		weight:             v.weight
		length:             v.length
		height:             v.height
		width:              v.width
		title:              v.title
		// image
		money_amounts: money_amounts
		option_values: option_values
	}
}

struct ProductResponse {
	id            string
	created_at    time.Time @[json: 'createdAt']
	updated_at    time.Time @[json: 'updatedAt']
	deleted_at    time.Time @[json: 'deletedAt'; omitempty]
	handle        string
	is_giftcard   bool @[json: 'isGiftcard']
	status        string
	thumbnail     string @[omitempty]
	collection_id string @[json: 'collectionId'; omitempty]
	type_id       string @[json: 'typeId'; omitempty]
	discountable  bool
	images        []ImageResponse              @[omitempty]
	options       []ProductOptionResponse      @[omitempty]
	variants      []VariantResponse            @[omitempty]
	translations  []ProductTranslationResponse @[omitempty]
	// tags         []Tag                 @[omitempty]
}

fn format_product_response(p Product) ProductResponse {
	mut images := []ImageResponse{len: p.images.len}
	for i := 0; i < p.images.len; i++ {
		images[i] = format_image_response(p.images[i])
	}

	mut options := []ProductOptionResponse{len: p.options.len}
	for i := 0; i < p.options.len; i++ {
		options[i] = format_product_option_response(p.options[i])
	}

	mut variants := []VariantResponse{len: p.variants.len}
	for i := 0; i < p.variants.len; i++ {
		variants[i] = format_variant_response(p.variants[i])
	}

	mut translations := []ProductTranslationResponse{len: p.translations.len}
	for i := 0; i < p.translations.len; i++ {
		translations[i] = format_product_translation_response(p.translations[i])
	}

	// TODO tags

	return ProductResponse{
		id:            p.id
		created_at:    p.created_at.Time
		updated_at:    p.updated_at.Time
		deleted_at:    p.deleted_at.Time
		handle:        p.handle
		is_giftcard:   p.is_giftcard
		status:        p.status
		thumbnail:     p.thumbnail
		collection_id: p.collection_id
		type_id:       p.type_id
		discountable:  p.discountable
		images:        images
		options:       options
		variants:      variants
		translations:  translations
		// tags:          tags
	}
}
