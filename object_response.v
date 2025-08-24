module peony

import net.http
import time
import veb

const error_id_invalid = 'Invalid id'
const error_id_generation = 'Failed to generate id'
const error_header_missing = 'Missing header'
const error_header_invalid = 'Invalid header'
const error_transaction_start = 'Failed to start transaction'
const error_transaction_commit = 'Failed to start transaction'
const error_transaction_rollback = 'Failed to rollback transaction'
const error_database_data_malformed = 'Data retrieved from database is malformed'

struct PeonySuccess {
	success bool
}

fn new_peony_success() PeonySuccess {
	return PeonySuccess{
		success: true
	}
}

fn success(mut ctx Context) veb.Result {
	return ctx.json(new_peony_success())
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

fn handle_error(mut ctx Context, status http.Status, message string, details string) veb.Result {
	ctx.res.set_status(status)
	return ctx.json(new_peony_error(message, details))
}

// 400 bad request
fn handle_error_400(mut ctx Context, message string, details string) veb.Result {
	return handle_error(mut ctx, http.Status.bad_request, message, details)
}

// 404 not found
fn handle_error_404(mut ctx Context, message string, details string) veb.Result {
	return handle_error(mut ctx, http.Status.not_found, message, details)
}

// 422 unprocessable content
fn handle_error_422(mut ctx Context, message string, details string) veb.Result {
	return handle_error(mut ctx, http.Status.unprocessable_entity, message, details)
}

// 500 internal server error
fn handle_error_500(mut ctx Context, message string, details string) veb.Result {
	return handle_error(mut ctx, http.Status.internal_server_error, message, details)
}

fn handle_error_login(mut ctx Context) veb.Result {
	return handle_error(mut ctx, http.Status.unauthorized, 'Invalid email or password',
		'No further details')
}

// count is the number of items, that match the filters, stored in the database.
// offset is the number of items skipped.
// fetch is the number of items requested.
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
	metadata   string    @[omitempty]
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
		metadata:   u.metadata.value
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

struct LocaleResponseEnvelope {
	locales []LocaleResponse
	count   i64
	offset  i32
	fetch   i32
}

struct CurrencyResponse {
	code           string
	decimal_digits i32  @[json: 'decimalDigits'; omitempty]
	includes_tax   bool @[json: 'includesTax']
}

fn format_currency_response(c Currency) CurrencyResponse {
	if c.decimal_digits.is_null {
		return CurrencyResponse{
			code:         c.code
			includes_tax: c.includes_tax
		}
	}

	return CurrencyResponse{
		code:           c.code
		decimal_digits: c.decimal_digits.value
		includes_tax:   c.includes_tax
	}
}

struct CurrencyResponseEnvelope {
	currencies []CurrencyResponse
	count      i64
	offset     i32
	fetch      i32
}

struct CountryResponse {
	code      string
	region_id string @[json: 'regionId'; omitempty]
}

fn format_country_response(c Country) !CountryResponse {
	mut region_id := ''
	if !c.region_id_bin.is_null {
		region_id = id_bin_to_string(c.region_id_bin.value)!
	}

	return CountryResponse{
		code:      c.code
		region_id: region_id
	}
}

struct CountryResponseListEnvelope {
	countries []CountryResponse
	count     i64
	offset    i32
	fetch     i32
}

struct StoreResponse {
	id                        string
	created_at                time.Time @[json: 'createdAt']
	updated_at                time.Time @[json: 'updatedAt']
	name                      string
	default_locale_id         string @[json: 'defaultLocaleId']
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
		default_locale_id:         s.default_locale_id
		default_currency_code:     s.default_currency_code
		default_stock_location_id: s.default_stock_location_id
		default_sales_channel_id:  s.default_sales_channel_id
		locales:                   locales
		currencies:                currencies
	}
}

struct StoreResponseEnvelope {
	store StoreResponse
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
	locale_id   string    @[json: 'localeId']
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
		locale_id:   p.locale_id
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
	locale_id               string @[json: 'localeId']
	name                    string
}

fn format_product_option_value_translation_response(p ProductOptionValueTranslation) ProductOptionValueTranslationResponse {
	return ProductOptionValueTranslationResponse{
		product_option_value_id: p.product_option_value_id
		locale_id:               p.locale_id
		name:                    p.name
	}
}

struct ProductOptionValueResponse {
	id           string
	option_id    string @[json: 'optionId']
	variant_id   string @[json: 'variantId']
	translations []ProductOptionValueTranslationResponse
}

fn format_product_option_value_response(p ProductOptionValue) ProductOptionValueResponse {
	mut translations := []ProductOptionValueTranslationResponse{len: p.translations.len}
	for i := 0; i < p.translations.len; i++ {
		translations[i] = format_product_option_value_translation_response(p.translations[i])
	}

	return ProductOptionValueResponse{
		id:           p.id
		option_id:    p.option_id
		variant_id:   p.variant_id
		translations: translations
	}
}

struct ProductOptionTranslationResponse {
	product_option_id string @[json: 'productOptionId']
	locale_id         string @[json: 'localeId']
	title             string
}

fn format_product_option_translation_response(p ProductOptionTranslation) ProductOptionTranslationResponse {
	return ProductOptionTranslationResponse{
		product_option_id: p.product_option_id
		locale_id:         p.locale_id
		title:             p.title
	}
}

struct ProductOptionResponse {
	id           string
	product_id   string                       @[json: 'productId']
	values       []ProductOptionValueResponse @[omitempty]
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

fn format_money_amount_response(m MoneyAmount) !MoneyAmountResponse {
	mut price_list_id := ''
	mut region_id := ''
	mut variant_id := ''
	if !m.price_list_id_bin.is_null {
		price_list_id = id_bin_to_string(m.price_list_id_bin.value)!
	}

	if !m.region_id_bin.is_null {
		region_id = id_bin_to_string(m.region_id_bin.value)!
	}

	if !m.variant_id_bin.is_null {
		variant_id = id_bin_to_string(m.variant_id_bin.value)!
	}

	return MoneyAmountResponse{
		id:            m.id
		currency_code: m.currency_code
		amount:        m.amount
		min_quantity:  m.min_quantity.value
		max_quantity:  m.max_quantity.value
		price_list_id: price_list_id
		region_id:     region_id
		variant_id:    variant_id
	}
}

struct TaxRateResponse {
	id         string
	created_at time.Time @[json: 'createdAt']
	updated_at time.Time @[json: 'updatedAt']
	deleted_at time.Time @[json: 'deletedAt'; omitempty]
	rate       f32       @[omitempty]
	code       string    @[omitempty]
	name       string
	tax_type   string @[json: 'taxType'; omitempty]
}

fn format_tax_rate_response(t TaxRate) TaxRateResponse {
	return TaxRateResponse{
		id:         t.id
		created_at: t.created_at.Time
		updated_at: t.updated_at.Time
		deleted_at: t.deleted_at.value.Time
		rate:       t.rate
		code:       t.code.value
		name:       t.name
		tax_type:   t.tax_type
	}
}

// tax_rates: applied to calculated_price
struct PricesResponse {
	currency_code                     string            @[json: 'currencyCode']
	original_price                    i32               @[json: 'originalPrice']
	original_price_does_include_tax   bool              @[json: 'originalPriceDoesIncludeTax']
	original_price_excluding_tax      i32               @[json: 'originalPriceExcludingTax']
	original_price_including_tax      i32               @[json: 'originalPriceIncludingTax']
	calculated_price                  i32               @[json: 'calculatedPrice']               // TODO tax quantity discounts price-lists
	calculated_price_does_include_tax bool              @[json: 'calculatedPriceDoesIncludeTax'] // TODO tax
	calculated_price_excluding_tax    i32               @[json: 'calculatedPriceExcludingTax']   // TODO tax
	calculated_price_including_tax    i32               @[json: 'calculatedPriceIncludingTax']   // TODO tax
	tax_rates                         []TaxRateResponse @[json: 'taxRates'; omitempty]           // TODO tax
}

fn format_prices_response(p Prices) PricesResponse {
	return PricesResponse{
		currency_code:                     p.currency_code
		original_price:                    p.original_price
		original_price_does_include_tax:   p.original_price_does_include_tax
		original_price_excluding_tax:      p.original_price_excluding_tax
		original_price_including_tax:      p.original_price_including_tax
		calculated_price:                  p.calculated_price
		calculated_price_does_include_tax: p.calculated_price_does_include_tax
		calculated_price_excluding_tax:    p.calculated_price_excluding_tax
		calculated_price_including_tax:    p.calculated_price_including_tax
		// tax_rates:                         p.tax_rates
	}
}

struct RegionResponse {
	id                 string
	name               string
	created_at         time.Time         @[json: 'createdAt']
	updated_at         time.Time         @[json: 'updatedAt']
	deleted_at         time.Time         @[json: 'deletedAt'; omitempty]
	currency_code      string            @[json: 'currencyCode']
	includes_tax       bool              @[json: 'includesTax']
	gift_cards_taxable bool              @[json: 'giftCardsTaxable']
	automatic_taxes    bool              @[json: 'automaticTaxes']
	tax_rates          []TaxRateResponse @[json: 'taxRates']
}

fn foramt_region_response(r Region) RegionResponse {
	mut tax_rates := []TaxRateResponse{len: r.tax_rates.len}
	for i := 0; i < r.tax_rates.len; i++ {
		tax_rates[i] = format_tax_rate_response(r.tax_rates[i])
	}

	return RegionResponse{
		id:                 r.id
		name:               r.name
		created_at:         r.created_at.Time
		updated_at:         r.updated_at.Time
		deleted_at:         r.deleted_at.value.Time
		currency_code:      r.currency_code
		includes_tax:       r.includes_tax
		gift_cards_taxable: r.gift_cards_taxable
		automatic_taxes:    r.automatic_taxes
		tax_rates:          tax_rates
	}
}

struct RegionResponseEnvelope {
	region RegionResponse
}

struct RegionResponseListEnvelope {
	regions []RegionResponse
	count   i64
	offset  i32
	fetch   i32
}

struct InventoryItemResponse {
	id                string
	created_at        time.Time @[json: 'createdAt']
	updated_at        time.Time @[json: 'updatedAt']
	deleted_at        time.Time @[json: 'deletedAt'; omitempty]
	requires_shipping bool
}

fn format_inventory_item_response(r InventoryItem) InventoryItemResponse {
	return InventoryItemResponse{
		id:                r.id
		created_at:        r.created_at.Time
		updated_at:        r.updated_at.Time
		deleted_at:        r.deleted_at.value.Time
		requires_shipping: r.requires_shipping
	}
}

struct VariantResponse {
	id                 string
	created_at         time.Time                    @[json: 'createdAt']
	updated_at         time.Time                    @[json: 'updatedAt']
	deleted_at         time.Time                    @[json: 'deletedAt'; omitempty]
	product_id         string                       @[json: 'productId']
	title              string                       @[omitempty]
	sku                string                       @[omitempty]
	barcode            string                       @[omitempty]
	ean                string                       @[omitempty]
	upc                string                       @[omitempty]
	variant_rank       i32                          @[json: 'variantRank']
	allow_backorder    bool                         @[json: 'allowBackorder']
	manage_inventory   bool                         @[json: 'manageInventory']
	hs_code            string                       @[json: 'hsCode'; omitempty]
	origin_country     string                       @[json: 'originCountry'; omitempty]
	mid_code           string                       @[json: 'midCode'; omitempty]
	material           string                       @[omitempty]
	weight             i32                          @[omitempty]
	length             i32                          @[omitempty]
	height             i32                          @[omitempty]
	width              i32                          @[omitempty]
	metadata           string                       @[omitempty]
	image              string                       @[omitempty] // TODO variant images
	option_values      []ProductOptionValueResponse @[json: 'optionValues'; omitempty]
	money_amounts      []MoneyAmountResponse        @[json: 'moneyAmounts'; omitempty]
	prices             PricesResponse               @[omitempty]
	inventory_items    []InventoryItemResponse      @[json: 'inventoryItems'; omitempty]
	inventory_quantity i32 @[json: 'inventoryQuantity']
}

fn format_variant_response(v Variant, variant_prices_map map[string]Prices) !VariantResponse {
	mut option_values := []ProductOptionValueResponse{len: v.option_values.len}
	for i := 0; i < v.option_values.len; i++ {
		option_values[i] = format_product_option_value_response(v.option_values[i])
	}

	mut money_amounts := []MoneyAmountResponse{len: v.money_amounts.len}
	for i := 0; i < v.money_amounts.len; i++ {
		money_amounts[i] = format_money_amount_response(v.money_amounts[i])!
	}

	mut inventory_items := []InventoryItemResponse{len: v.inventory_items.len}
	for i := 0; i < v.inventory_items.len; i++ {
		inventory_items[i] = format_inventory_item_response(v.inventory_items[i])
	}

	prices := format_prices_response(variant_prices_map[v.id])
	inventory_quantity := i32(0) // TODO

	return VariantResponse{
		id:               v.id
		created_at:       v.created_at.Time
		updated_at:       v.updated_at.Time
		deleted_at:       v.deleted_at.Time
		product_id:       v.product_id
		sku:              v.sku
		barcode:          v.barcode
		ean:              v.ean
		upc:              v.upc
		variant_rank:     v.variant_rank
		allow_backorder:  v.allow_backorder
		manage_inventory: v.manage_inventory
		hs_code:          v.hs_code
		origin_country:   v.origin_country
		mid_code:         v.mid_code
		material:         v.material
		weight:           v.weight
		length:           v.length
		height:           v.height
		width:            v.width
		title:            v.title
		metadata:         v.metadata.value
		// image:
		option_values:      option_values
		money_amounts:      money_amounts
		inventory_items:    inventory_items
		prices:             prices
		inventory_quantity: inventory_quantity
	}
}

fn format_variant_response_admin(v Variant) !VariantResponse {
	variants_prices_map := map[string]Prices{}
	return format_variant_response(v, variants_prices_map)
}

struct VariantResponseEnvelope {
	variant VariantResponse
}

struct VariantResponseListEnvelope {
	variants []VariantResponse
	count    i64
	offset   i32
	fetch    i32
}

struct SalesChannelResponse {
	id          string
	created_at  time.Time @[json: 'createdAt']
	updated_at  time.Time @[json: 'updatedAt']
	deleted_at  time.Time @[json: 'deletedAt'; omitempty]
	name        string
	description string @[omitempty]
	is_disabled bool
}

fn format_sales_channel_response(v SalesChannel) SalesChannelResponse {
	return SalesChannelResponse{
		id:          v.id
		created_at:  v.created_at.Time
		updated_at:  v.updated_at.Time
		deleted_at:  v.deleted_at.Time
		name:        v.name
		description: v.description
		is_disabled: v.is_disabled
	}
}

struct SalesChannelResponseEnvelope {
	sales_channels []SalesChannelResponse @[json: 'salesChannels']
	count          i64
	offset         i32
	fetch          i32
}

struct ProductResponse {
	id             string
	created_at     time.Time @[json: 'createdAt']
	updated_at     time.Time @[json: 'updatedAt']
	deleted_at     time.Time @[json: 'deletedAt'; omitempty]
	handle         string
	is_giftcard    bool @[json: 'isGiftcard']
	status         string
	thumbnail      string @[omitempty]
	collection_id  string @[json: 'collectionId'; omitempty]
	type_id        string @[json: 'typeId'; omitempty]
	discountable   bool
	metadata       string                       @[omitempty]
	images         []ImageResponse              @[omitempty]
	options        []ProductOptionResponse      @[omitempty]
	variants       []VariantResponse            @[omitempty]
	translations   []ProductTranslationResponse @[omitempty]
	sales_channels []SalesChannelResponse       @[json: 'salesChannels']
	// tags         []Tag                 @[omitempty]
}

fn format_product_response_store(p Product, variant_prices_map map[string]Prices) !ProductResponse {
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
		variants[i] = format_variant_response(p.variants[i], variant_prices_map)!
	}

	mut translations := []ProductTranslationResponse{len: p.translations.len}
	for i := 0; i < p.translations.len; i++ {
		translations[i] = format_product_translation_response(p.translations[i])
	}

	mut sales_channels := []SalesChannelResponse{len: p.sales_channels.len}
	for i := 0; i < p.sales_channels.len; i++ {
		sales_channels[i] = format_sales_channel_response(p.sales_channels[i])
	}

	// TODO tags

	return ProductResponse{
		id:             p.id
		created_at:     p.created_at.Time
		updated_at:     p.updated_at.Time
		deleted_at:     p.deleted_at.Time
		handle:         p.handle
		is_giftcard:    p.is_giftcard
		status:         p.status
		thumbnail:      p.thumbnail
		collection_id:  p.collection_id
		type_id:        p.type_id
		discountable:   p.discountable
		metadata:       p.metadata.value
		images:         images
		options:        options
		variants:       variants
		translations:   translations
		sales_channels: sales_channels
		// tags:          tags
	}
}

fn format_product_response_admin(p Product) !ProductResponse {
	variant_prices_map := map[string]Prices{} // no prices needed here
	return format_product_response_store(p, variant_prices_map)
}

struct ProductResponseEnvelope {
	product ProductResponse
}

struct ProductResponseListEnvelope {
	products []ProductResponse
	count    i64
	offset   i32
	fetch    i32
}

struct UploadsUploadResponseEnvelope {
	uploads []BlobProviderFileData
}

struct UploadsDeleteResponse {
	id      string
	deleted bool
}

struct ProductCategoryTranslationResponse {
	product_category_id string @[json: 'productCategoryId']
	locale_id           string @[json: 'localeId']
	name                string
	description         string @[omitempty]
}

struct ProductCategoryResponse {
	id                 string
	created_at         time.Time @[json: 'createdAt']
	updated_at         time.Time @[json: 'updatedAt']
	deleted_at         time.Time @[json: 'deletedAt'; omitempty]
	handle             string
	is_active          bool   @[json: 'isActive']
	is_internal        bool   @[json: 'isInternal']
	parent_category_id string @[json: 'parentCategoryId'; omitempty]
	category_rank      i32    @[json: 'categoryRank']
	metadata           string @[omitempty]
	translations       []ProductCategoryTranslationResponse
}

struct ProductCategoryResponseListEnvelope {
	product_categories []ProductCategoryResponse @[json: 'productCategories']
	count              i64
	offset             i32
	fetch              i32
}

fn format_product_category_response(p ProductCategory) ProductCategoryResponse {
	mut tr := []ProductCategoryTranslationResponse{len: p.translations.len}
	for i := 0; i < p.translations.len; i++ {
		translation := p.translations[i]
		tr[i] = ProductCategoryTranslationResponse{
			product_category_id: translation.product_category_id
			locale_id:           translation.locale_id
			name:                translation.name
			description:         translation.description.value
		}
	}

	return ProductCategoryResponse{
		id:                 p.id
		created_at:         p.created_at.Time
		updated_at:         p.updated_at.Time
		deleted_at:         p.deleted_at.value.Time
		handle:             p.handle
		is_active:          p.is_active
		is_internal:        p.is_internal
		parent_category_id: p.parent_category_id
		category_rank:      p.category_rank
		metadata:           p.metadata.value
		translations:       tr
	}
}
