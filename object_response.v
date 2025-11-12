module peony

import time

struct PeonySuccess {
	success bool
}

struct PeonyError {
	Error
	message string
	details string
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

struct UserResponseEnvelope {
	user UserResponse
}

struct LocaleResponse {
	id   string
	code string
}

struct LocaleResponseEnvelope {
	locale LocaleResponse
}

struct ListLocaleResponseEnvelope {
	locales []LocaleResponse
	count   i64
	offset  i32
	fetch   i32 @[omitempty]
}

struct CurrencyResponse {
	code           string
	decimal_digits i32 @[json: 'decimalDigits'; omitempty]
}

struct CurrencyResponseEnvelope {
	currencies []CurrencyResponse
	count      i64
	offset     i32
	fetch      i32 @[omitempty]
}

struct CountryResponse {
	code      string
	region_id string @[json: 'regionId'; omitempty]
}

struct CountryResponseListEnvelope {
	countries []CountryResponse
	count     i64
	offset    i32
	fetch     i32 @[omitempty]
}

struct StoreResponse {
	id                        string
	created_at                time.Time @[json: 'createdAt']
	updated_at                time.Time @[json: 'updatedAt']
	name                      string
	default_region_id         string @[json: 'defaultRegionId']
	default_locale_id         string @[json: 'defaultLocaleId']
	default_stock_location_id string @[json: 'defaultStockLocationId'; omitempty]
	default_sales_channel_id  string @[json: 'defaultSalesChannelId'; omitempty]
	default_currency_code     string @[json: 'defaultCurrencyCode']
	locales                   []LocaleResponse
	currencies                []CurrencyResponse
}

struct StoreResponseEnvelope {
	store StoreResponse
}

struct ImageTranslationResponse {
	image_id  string @[json: 'imageId']
	locale_id string @[json: 'localeId']
	alt       string
}

struct ProductImageResponse {
	id           string
	url          string
	product_id   string                     @[json: 'productId']
	image_rank   i32                        @[json: 'imageRank']
	alt          string                     @[omitempty]
	translations []ImageTranslationResponse @[omitempty]
}

struct ProductTranslationResponse {
	product_id  string @[json: 'productId']
	locale_id   string @[json: 'localeId']
	title       string @[omitempty]
	subtitle    string @[omitempty]
	description string @[omitempty]
}

struct ProductOptionValueTranslationResponse {
	option_value_id string @[json: 'optionValueId']
	locale_id       string @[json: 'localeId']
	name            string
}

fn format_product_option_value_translation_response(p ProductOptionValueTranslation) ProductOptionValueTranslationResponse {
	return ProductOptionValueTranslationResponse{
		option_value_id: p.option_value_id
		locale_id:       p.locale_id
		name:            p.name
	}
}

struct ProductOptionValueResponse {
	id           string
	option_id    string @[json: 'optionId']
	name         string
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
		name:         p.name
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
	product_id   string @[json: 'productId']
	title        string
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
		product_id:   p.product_id
		values:       values
		title:        p.title
		translations: translations
	}
}

struct ProductOptionListEnvelope {
	options []ProductOptionResponse
	count   i64
	offset  i32
	fetch   i32 @[omitempty]
}

struct MoneyAmountResponse {
	id            string
	currency_code string @[json: 'currencyCode']
	amount        i32
	min_quantity  i32    @[json: 'minQuantity'; omitempty]
	max_quantity  i32    @[json: 'maxQuantity'; omitempty]
	price_list_id string @[json: 'priceListId'; omitempty]
	region_id     string @[json: 'regionId'; omitempty] // TODO this should always set
	variant_id    string @[json: 'variantId'; omitempty]
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

struct RegionResponseEnvelope {
	region RegionResponse
}

struct RegionResponseListEnvelope {
	regions []RegionResponse
	count   i64
	offset  i32
	fetch   i32 @[omitempty]
}

struct InventoryLevelResponse {
	inventory_item_id string @[json: 'inventoryItemId']
	stock_location_id string @[json: 'stockLocationId']
	stocked_quantity  i32    @[json: 'stockedQuantity']
	reserved_quantity i32    @[json: 'reservedQuantity']
}

struct InventoryItemResponse {
	id                string
	created_at        time.Time                @[json: 'createdAt']
	updated_at        time.Time                @[json: 'updatedAt']
	deleted_at        time.Time                @[json: 'deletedAt'; omitempty]
	variant_id        string                   @[json: 'variantId']
	sku               string                   @[omitempty]
	origin_country    string                   @[json: 'originCountry'; omitempty]
	hs_code           string                   @[json: 'hsCode'; omitempty]
	mid_code          string                   @[json: 'midCode'; omitempty]
	material          string                   @[omitempty]
	weight            i32                      @[omitempty]
	length            i32                      @[omitempty]
	height            i32                      @[omitempty]
	width             i32                      @[omitempty]
	requires_shipping bool                     @[json: 'requiresShipping']
	manage_inventory  bool                     @[json: 'manageInventory']
	allow_backorder   bool                     @[json: 'allowBackorder']
	inventory_levels  []InventoryLevelResponse @[json: 'inventoryLevels'; omitempty]
}

struct ProductVariantResponse {
	id                 string
	created_at         time.Time                    @[json: 'createdAt']
	updated_at         time.Time                    @[json: 'updatedAt']
	deleted_at         time.Time                    @[json: 'deletedAt'; omitempty]
	product_id         string                       @[json: 'productId']
	title              string                       @[omitempty]
	barcode            string                       @[omitempty]
	ean                string                       @[omitempty]
	upc                string                       @[omitempty]
	variant_rank       i32                          @[json: 'variantRank']
	metadata           string                       @[omitempty]
	image              string                       @[omitempty]
	option_values      []ProductOptionValueResponse @[json: 'optionValues'; omitempty]
	money_amounts      []MoneyAmountResponse        @[json: 'moneyAmounts'; omitempty]
	inventory_item     InventoryItemResponse        @[json: 'inventoryItem'; omitempty]
	purchasable        bool
	inventory_quantity i32            @[json: 'inventoryQuantity']
	prices             PricesResponse @[omitempty]
}

struct VariantResponseEnvelope {
	variant ProductVariantResponse
}

struct VariantResponseListEnvelope {
	variants []ProductVariantResponse
	count    i64
	offset   i32
	fetch    i32 @[omitempty]
}

struct SalesChannelResponse {
	id          string
	created_at  time.Time @[json: 'createdAt']
	updated_at  time.Time @[json: 'updatedAt']
	deleted_at  time.Time @[json: 'deletedAt'; omitempty]
	name        string
	description string @[omitempty]
	is_disabled bool   @[json: 'isDisabled']
}

struct SalesChannelResponseEnvelope {
	sales_channels []SalesChannelResponse @[json: 'salesChannels']
	count          i64
	offset         i32
	fetch          i32 @[omitempty]
}

struct ProductResponse {
	id           string
	created_at   time.Time @[json: 'createdAt']
	updated_at   time.Time @[json: 'updatedAt']
	deleted_at   time.Time @[json: 'deletedAt'; omitempty]
	handle       string
	is_giftcard  bool @[json: 'isGiftcard']
	status       string
	thumbnail    string @[omitempty]
	type_id      string @[json: 'typeId'; omitempty]
	discountable bool
	metadata     string                    @[omitempty]
	title        string                    @[omitempty]
	subtitle     string                    @[omitempty]
	description  string                    @[omitempty]
	categories   []ProductCategoryResponse @[omitempty]
	// collections    []ProductCollectionResponse  @[omitempty]
	images         []ProductImageResponse       @[omitempty]
	options        []ProductOptionResponse      @[omitempty]
	variants       []ProductVariantResponse     @[omitempty]
	translations   []ProductTranslationResponse @[omitempty]
	sales_channels []SalesChannelResponse       @[json: 'salesChannels']
	// tags         []Tag                 @[omitempty]
}

struct ProductResponseEnvelope {
	product ProductResponse
}

struct ProductResponseListEnvelope {
	products []ProductResponse
	count    i64
	offset   i32
	fetch    i32 @[omitempty]
}

struct UploadsUploadResponseEnvelope {
	uploads []ProviderBlobFileData
}

struct UploadsUploadOneResponseEnvelope {
	upload ProviderBlobFileData
}

struct UploadsDeleteResponse {
	id      string
	deleted bool
}

struct ProductCategoryTranslationResponse {
	product_category_id string @[json: 'productCategoryId']
	locale_id           string @[json: 'localeId']
	name                string @[omitempty]
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
	name               string @[omitempty]
	description        string @[omitempty]
	translations       []ProductCategoryTranslationResponse
}

struct ProductCategoryResponseListEnvelope {
	product_categories []ProductCategoryResponse @[json: 'productCategories']
	count              i64
	offset             i32
	fetch              i32 @[omitempty]
}

struct StockLocationResponse {
	id         string
	created_at time.Time @[json: 'createdAt']
	updated_at time.Time @[json: 'updatedAt']
	deleted_at time.Time @[json: 'deletedAt'; omitempty]
	name       string
}

fn format_stock_location_response(p StockLocation) StockLocationResponse {
	return StockLocationResponse{
		id:         p.id
		created_at: p.created_at.Time
		updated_at: p.updated_at.Time
		deleted_at: p.deleted_at.value.Time
		name:       p.name
	}
}

struct StockLocationResponseListEnvelope {
	stock_locations []StockLocationResponse @[json: 'stockLocations']
	count           i64
	offset          i32
	fetch           i32 @[omitempty]
}
