module peony

import log
import time

pub struct PeonySuccess {
	success bool
}

pub struct PeonyError {
	Error
	message string
	details string
}

pub struct UserResponse {
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

pub struct UserResponseEnvelope {
	user UserResponse
}

pub struct LocaleResponse {
	id   string
	code string
}

pub struct LocaleResponseEnvelope {
	locale LocaleResponse
}

pub struct ListLocaleResponseEnvelope {
	locales []LocaleResponse
	count   i64
	offset  i32
	fetch   i32 @[omitempty]
}

pub struct CurrencyResponse {
	code           string
	decimal_digits i32 @[json: 'decimalDigits'; omitempty]
}

pub struct CurrencyResponseEnvelope {
	currency CurrencyResponse
}

pub struct CurrencyResponseListEnvelope {
	currencies []CurrencyResponse
	count      i64
	offset     i32
	fetch      i32 @[omitempty]
}

pub struct CountryResponse {
	code      string
	region_id string @[json: 'regionId'; omitempty]
}

pub struct CountryResponseListEnvelope {
	countries []CountryResponse
	count     i64
	offset    i32
	fetch     i32 @[omitempty]
}

pub struct StoreResponse {
	id                        string
	created_at                time.Time @[json: 'createdAt']
	updated_at                time.Time @[json: 'updatedAt']
	name                      string
	default_region_id         string @[json: 'defaultRegionId']
	default_locale_id         string @[json: 'defaultLocaleId']
	default_stock_location_id string @[json: 'defaultStockLocationId']
	default_sales_channel_id  string @[json: 'defaultSalesChannelId']
	default_currency_code     string @[json: 'defaultCurrencyCode']
	locales                   []LocaleResponse
	currencies                []CurrencyResponse
}

pub struct StoreResponseEnvelope {
	store StoreResponse
}

pub struct ImageTranslationResponse {
	image_id  string @[json: 'imageId']
	locale_id string @[json: 'localeId']
	alt       string
}

pub struct ProductImageResponse {
	id           string
	url          string
	product_id   string                     @[json: 'productId']
	image_rank   i32                        @[json: 'imageRank']
	alt          string                     @[omitempty]
	translations []ImageTranslationResponse @[omitempty]
}

pub struct ProductTranslationResponse {
	product_id  string @[json: 'productId']
	locale_id   string @[json: 'localeId']
	title       string @[omitempty]
	subtitle    string @[omitempty]
	description string @[omitempty]
}

pub struct ProductOptionValueTranslationResponse {
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

pub struct ProductOptionValueResponse {
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

pub struct ProductOptionTranslationResponse {
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

pub struct ProductOptionResponse {
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

pub struct ProductOptionListEnvelope {
	options []ProductOptionResponse
	count   i64
	offset  i32
	fetch   i32 @[omitempty]
}

pub struct MoneyAmountResponse {
	id            string
	currency_code string @[json: 'currencyCode']
	amount        i32
	min_quantity  i32    @[json: 'minQuantity'; omitempty]
	max_quantity  i32    @[json: 'maxQuantity'; omitempty]
	price_list_id string @[json: 'priceListId'; omitempty]
	region_id     string @[json: 'regionId']
	variant_id    string @[json: 'variantId'; omitempty]
}

pub struct TaxRateResponse {
	id         string
	created_at time.Time @[json: 'createdAt']
	updated_at time.Time @[json: 'updatedAt']
	deleted_at time.Time @[json: 'deletedAt'; omitempty]
	rate       f32       @[omitempty]
	code       string    @[omitempty]
	name       string
	tax_type   string @[json: 'taxType'; omitempty]
}

pub struct ProductVariantPriceResponse {
	currency_code  string @[json: 'currencyCode']
	includes_tax   bool   @[json: 'includesTax']
	original_price i32    @[json: 'originalPrice'; omitempty]
	base_price     i32    @[json: 'basePrice']
}

fn format_price_response(p ProductVariantPrice) ProductVariantPriceResponse {
	return ProductVariantPriceResponse{
		currency_code:  p.currency_code
		includes_tax:   p.includes_tax
		original_price: p.original_price
		base_price:     p.base_price
	}
}

pub struct RegionResponse {
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

pub struct RegionResponseEnvelope {
	region RegionResponse
}

pub struct RegionResponseListEnvelope {
	regions []RegionResponse
	count   i64
	offset  i32
	fetch   i32 @[omitempty]
}

pub struct InventoryLevelResponse {
	inventory_item_id string @[json: 'inventoryItemId']
	stock_location_id string @[json: 'stockLocationId']
	stocked_quantity  i32    @[json: 'stockedQuantity']
	reserved_quantity i32    @[json: 'reservedQuantity']
}

pub struct InventoryItemResponse {
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

pub struct VariantResponse {
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
	inventory_quantity i32 @[json: 'inventoryQuantity']
}

fn format_variant_response(v ProductVariant) VariantResponse {
	mut option_values := []ProductOptionValueResponse{len: v.option_values.len}
	for i := 0; i < v.option_values.len; i++ {
		option_values[i] = format_product_option_value_response(v.option_values[i])
	}

	mut money_amounts := []MoneyAmountResponse{len: v.money_amounts.len}
	for i := 0; i < v.money_amounts.len; i++ {
		money_amounts[i] = format_money_amount_response(v.money_amounts[i])
	}

	return VariantResponse{
		id:           v.id
		created_at:   v.created_at.Time
		updated_at:   v.updated_at.Time
		deleted_at:   v.deleted_at.value.Time
		product_id:   v.product_id
		title:        v.title.value
		barcode:      v.barcode.value
		ean:          v.ean.value
		upc:          v.upc.value
		variant_rank: v.variant_rank
		metadata:     v.metadata.value
		// TODO images
		inventory_item:     format_inventory_item_response(v.inventory_item)
		inventory_quantity: get_inventory_quantity(v.inventory_item)
		option_values:      option_values
		money_amounts:      money_amounts
	}
}

pub struct VariantResponseStore {
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
	inventory_quantity i32 @[json: 'inventoryQuantity']
	purchasable        bool
	price              ProductVariantPriceResponse
}

fn format_variant_response_store(v ProductVariant, p ProductVariantPrice, product_variants_availability map[string]ProductVariantAvailability) VariantResponseStore {
	product_variant_availability := product_variants_availability[v.id]

	mut option_values := []ProductOptionValueResponse{len: v.option_values.len}
	for i := 0; i < v.option_values.len; i++ {
		option_values[i] = format_product_option_value_response(v.option_values[i])
	}

	return VariantResponseStore{
		id:           v.id
		created_at:   v.created_at.Time
		updated_at:   v.updated_at.Time
		deleted_at:   v.deleted_at.value.Time
		product_id:   v.product_id
		title:        v.title.value
		barcode:      v.barcode.value
		ean:          v.ean.value
		upc:          v.upc.value
		variant_rank: v.variant_rank
		metadata:     v.metadata.value
		// TODO images
		inventory_quantity: product_variant_availability.inventory_quantity
		option_values:      option_values
		price:              format_price_response(p) // TODO not for /admin/
		purchasable:        product_variant_availability.purchasable
	}
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

pub struct SEOTranslationResponse {
	id          string
	locale_id   string @[json: 'localeId']
	title       string @[omitempty]
	description string @[omitempty]
}

fn format_seo_translation_response(p ProductSEOTranslation) SEOTranslationResponse {
	return SEOTranslationResponse{
		id:          p.id
		locale_id:   p.locale_id
		title:       p.title.value
		description: p.description.value
	}
}

pub struct ProductCategoryTranslationResponse {
	product_category_id string @[json: 'productCategoryId']
	locale_id           string @[json: 'localeId']
	name                string @[omitempty]
	description         string @[omitempty]
}

pub struct ProductCategoryResponse {
	id                 string
	created_at         time.Time @[json: 'createdAt']
	updated_at         time.Time @[json: 'updatedAt']
	deleted_at         time.Time @[json: 'deletedAt'; omitempty]
	handle             string
	parent_category_id string @[json: 'parentCategoryId'; omitempty]
	is_active          bool   @[json: 'isActive']
	is_internal        bool   @[json: 'isInternal']
	category_rank      i32    @[json: 'categoryRank']
	metadata           string @[omitempty]
	name               string @[omitempty]
	description        string @[omitempty]
	seo_title          string @[omitempty]
	seo_description    string @[omitempty]
	translations       []ProductCategoryTranslationResponse
	seo_translations   []SEOTranslationResponse @[json: 'seoTranslations'; omitempty]
}

fn format_product_category_response(p ProductCategory) ProductCategoryResponse {
	mut tr := []ProductCategoryTranslationResponse{len: p.translations.len}
	for i := 0; i < p.translations.len; i++ {
		translation := p.translations[i]
		tr[i] = ProductCategoryTranslationResponse{
			product_category_id: translation.product_category_id
			locale_id:           translation.locale_id
			name:                translation.name.value
			description:         translation.description.value
		}
	}

	return ProductCategoryResponse{
		id:                 p.id
		created_at:         p.created_at.Time
		updated_at:         p.updated_at.Time
		deleted_at:         p.deleted_at.value.Time
		handle:             p.handle
		parent_category_id: p.parent_category_id
		is_active:          p.is_active
		is_internal:        p.is_internal
		category_rank:      p.category_rank
		metadata:           p.metadata.value
		name:               p.name.value
		description:        p.description.value
		translations:       tr
	}
}

pub struct ProductCategoryResponseEnvelope {
	category ProductCategoryResponse
}

pub struct ProductCategoryResponseListEnvelope {
	categories []ProductCategoryResponse
	count      i64
	offset     i32
	fetch      i32 @[omitempty]
}

pub struct CategoryResponseStore {
	id                 string
	created_at         time.Time @[json: 'createdAt']
	updated_at         time.Time @[json: 'updatedAt']
	handle             string
	parent_category_id string @[json: 'parentCategoryId'; omitempty]
	category_rank      i32    @[json: 'categoryRank']
	metadata           string @[omitempty]
	name               string @[omitempty]
	description        string @[omitempty]
	seo_title          string @[omitempty]
	seo_description    string @[omitempty]
}

fn format_category_response_store(p ProductCategory) CategoryResponseStore {
	return CategoryResponseStore{
		id:                 p.id
		created_at:         p.created_at.Time
		updated_at:         p.updated_at.Time
		handle:             p.handle
		parent_category_id: p.parent_category_id
		category_rank:      p.category_rank
		metadata:           p.metadata.value
		name:               p.name.value
		description:        p.description.value
	}
}

pub struct CategoryResponseStoreEnvelope {
	category CategoryResponseStore
}

pub struct CategoryResponseStoreListEnvelope {
	categories []CategoryResponseStore
	count      i64
	offset     i32
	fetch      i32 @[omitempty]
}

pub struct VariantResponseEnvelope {
	variant VariantResponse
}

pub struct SalesChannelResponse {
	id          string
	created_at  time.Time @[json: 'createdAt']
	updated_at  time.Time @[json: 'updatedAt']
	deleted_at  time.Time @[json: 'deletedAt'; omitempty]
	name        string
	description string @[omitempty]
	is_disabled bool   @[json: 'isDisabled']
}

pub struct SalesChannelResponseEnvelope {
	sales_channels []SalesChannelResponse @[json: 'salesChannels']
	count          i64
	offset         i32
	fetch          i32 @[omitempty]
}

pub struct ProductResponse {
	id                string
	created_at        time.Time @[json: 'createdAt']
	updated_at        time.Time @[json: 'updatedAt']
	deleted_at        time.Time @[json: 'deletedAt'; omitempty]
	handle            string
	is_giftcard       bool @[json: 'isGiftcard']
	status            string
	thumbnail         string @[omitempty]
	type_id           string @[json: 'typeId'; omitempty]
	discountable      bool
	translations      []ProductTranslationResponse
	metadata          string @[omitempty]
	title             string
	subtitle          string                   @[omitempty]
	description       string                   @[omitempty]
	seo_title         string                   @[json: 'seoTitle'; omitempty]
	seo_description   string                   @[json: 'seoDescription'; omitempty]
	category_ids      []string                 @[json: 'categoryIds'; omitempty]
	images            []ProductImageResponse   @[omitempty]
	options           []ProductOptionResponse  @[omitempty]
	variants          []VariantResponse        @[omitempty]
	sales_channel_ids []string                 @[json: 'salesChannels']
	seo_translations  []SEOTranslationResponse @[json: 'seoTranslations'; omitempty]
	// collections  []ProductCollectionResponse @[omitempty] // return ids only
	// tags         []Tag                       @[omitempty] // return ids only
}

fn format_product_response(p Product) ProductResponse {
	mut type_id := ''
	if !p.type_id_bin.is_null {
		type_id = id_bin_to_string(p.type_id_bin.value) or {
			log.error(error_database_data_malformed)
			log.error('product.type_id_bin is invalid')
			''
		}
	}

	mut images := []ProductImageResponse{len: p.images.len}
	for i := 0; i < p.images.len; i++ {
		images[i] = format_product_image_response(p.images[i])
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

	return ProductResponse{
		id:                p.id
		created_at:        p.created_at.Time
		updated_at:        p.updated_at.Time
		deleted_at:        p.deleted_at.value.Time
		handle:            p.handle
		is_giftcard:       p.is_giftcard
		status:            p.status
		thumbnail:         p.thumbnail.value
		type_id:           type_id
		discountable:      p.discountable
		metadata:          p.metadata.value
		title:             p.title.value
		subtitle:          p.subtitle.value
		description:       p.description.value
		images:            images
		options:           options
		variants:          variants
		category_ids:      p.category_ids
		sales_channel_ids: p.sales_channels_ids
		translations:      translations
		// tags:          tags
	}
}

pub struct ProductResponseEnvelope {
	product ProductResponse
}

pub struct ProductResponseListEnvelope {
	products []ProductResponse
	count    i64
	offset   i32
	fetch    i32 @[omitempty]
}

pub struct ProductResponseStore {
	id              string
	created_at      time.Time @[json: 'createdAt']
	updated_at      time.Time @[json: 'updatedAt']
	deleted_at      time.Time @[json: 'deletedAt'; omitempty]
	handle          string
	is_giftcard     bool @[json: 'isGiftcard']
	status          string
	thumbnail       string @[omitempty]
	type_id         string @[json: 'typeId'; omitempty]
	discountable    bool
	metadata        string @[omitempty]
	title           string
	subtitle        string                  @[omitempty]
	description     string                  @[omitempty]
	seo_title       string                  @[json: 'seoTitle'; omitempty]
	seo_description string                  @[json: 'seoDescription'; omitempty]
	category_ids    []string                @[json: 'categoryIds'; omitempty]
	images          []ProductImageResponse  @[omitempty]
	options         []ProductOptionResponse @[omitempty]
	variants        []VariantResponseStore  @[omitempty]
	// collections  []ProductCollectionResponse @[omitempty]
	// tags         []Tag                       @[omitempty]
}

fn format_product_response_store(p Product, pctx PriceContext, product_variants_availability map[string]ProductVariantAvailability) ProductResponseStore {
	mut type_id := ''
	if !p.type_id_bin.is_null {
		type_id = id_bin_to_string(p.type_id_bin.value) or {
			log.error(error_database_data_malformed)
			log.error('product.type_id_bin is invalid')
			''
		}
	}

	mut images := []ProductImageResponse{len: p.images.len}
	for i := 0; i < p.images.len; i++ {
		images[i] = format_product_image_response(p.images[i])
	}

	mut options := []ProductOptionResponse{len: p.options.len}
	for i := 0; i < p.options.len; i++ {
		options[i] = format_product_option_response(p.options[i])
	}

	mut variants := []VariantResponseStore{len: p.variants.len}
	for i := 0; i < p.variants.len; i++ {
		variant := p.variants[i]
		prices := calculate_price(variant, 1, pctx)
		variants[i] = format_variant_response_store(variant, prices, product_variants_availability)
	}

	// mut collections := []ProductCollectionResponse{len: p.collections.len}
	// for i := 0; i < p.collections.len; i++ {
	// 	collections[i] = format_product_collection_response(p.collections[i])
	// }

	// TODO tags

	return ProductResponseStore{
		id:           p.id
		created_at:   p.created_at.Time
		updated_at:   p.updated_at.Time
		deleted_at:   p.deleted_at.value.Time
		handle:       p.handle
		is_giftcard:  p.is_giftcard
		status:       p.status
		thumbnail:    p.thumbnail.value
		type_id:      type_id
		discountable: p.discountable
		metadata:     p.metadata.value
		title:        p.title.value
		subtitle:     p.subtitle.value
		description:  p.description.value
		images:       images
		options:      options
		variants:     variants
		category_ids: p.category_ids
		// collections:    collections
		// tags:          tags
	}
}

pub struct ProductResponseStoreEnvelope {
	product ProductResponseStore
}

pub struct ProductResponseStoreListEnvelope {
	products []ProductResponseStore
	count    i64
	offset   i32
	fetch    i32 @[omitempty]
}

pub struct UploadsUploadResponseEnvelope {
	uploads []ProviderBlobFileData
}

pub struct UploadsUploadOneResponseEnvelope {
	upload ProviderBlobFileData
}

pub struct UploadsDeleteResponse {
	id      string
	deleted bool
}

pub struct StockLocationResponse {
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

pub struct StockLocationResponseListEnvelope {
	stock_locations []StockLocationResponse @[json: 'stockLocations']
	count           i64
	offset          i32
	fetch           i32 @[omitempty]
}
