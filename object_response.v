module peony

import time
import einar_hjortdal.firebird
import providers
import internal.conduit

fn format_none_date_time(ndt ?firebird.DateTime) ?time.Time {
	date_time := ndt or { return none }
	return date_time.Time
}

fn format_none_id(nid ?ID) ?string {
	id := nid or { return none }
	return id.string()
}

fn format_array_id(aid []ID) []string {
	mut res := []string{len: aid.len}
	for i := 0; i < aid.len; i++ {
		res[i] = aid[i].string()
	}
	return res
}

pub struct DeletedResponse {}

pub struct PeonyErrorResponse {
pub:
	message string
	details string @[omitempty]
}

pub struct IDResponseEnvelope {
pub:
	id string
}

pub struct APIKeyResponse {
pub:
	id               string
	created_at       time.Time  @[json: 'createdAt']
	updated_at       time.Time  @[json: 'updatedAt']
	deleted_at       ?time.Time @[json: 'deletedAt'; omitempty]
	name             string
	sales_channel_id string
}

fn format_api_key_response(p conduit.APIKey) APIKeyResponse {
	return APIKeyResponse{
		id:               p.id.string()
		created_at:       p.created_at.Time
		updated_at:       p.updated_at.Time
		deleted_at:       format_none_date_time(p.deleted_at)
		name:             p.name
		sales_channel_id: p.sales_channel_id.string()
	}
}

pub struct APIKeyResponseEnvelope {
pub:
	api_key APIKeyResponse @[json: 'apiKey']
}

pub struct APIKeyResponseListEnvelope {
pub:
	api_keys []APIKeyResponse @[json: 'apiKeys']
	count    i64
	offset   i32
	fetch    i32
}

pub struct UserResponse {
pub:
	id         string
	handle     string
	email      string
	role       string
	created_at time.Time  @[json: 'createdAt']
	updated_at time.Time  @[json: 'updatedAt']
	deleted_at ?time.Time @[json: 'deletedAt'; omitempty]
	first_name string     @[json: 'firstName'; omitempty]
	last_name  string     @[json: 'lastName'; omitempty]
	metadata   ?string    @[omitempty]
}

fn format_user_response(u conduit.User) UserResponse {
	return UserResponse{
		id:         u.id.string()
		handle:     u.handle
		email:      u.email
		role:       u.role
		created_at: u.created_at.Time
		updated_at: u.updated_at.Time
		deleted_at: format_none_date_time(u.deleted_at)
		first_name: u.first_name
		last_name:  u.last_name
		metadata:   u.metadata
	}
}

pub struct UserResponseEnvelope {
pub:
	user UserResponse
}

// users: the list of users
// count: the total count of items.
// offset: the number of items skipped before retrieving the returned items.
// fetch: the maximum number of items returned.
pub struct UserResponseListEnvelope {
pub:
	users  []UserResponse
	count  i64
	offset i32
	fetch  i32
}

pub struct LocaleResponse {
pub:
	id   string
	code string
}

fn format_locale_response(l conduit.Locale) LocaleResponse {
	return LocaleResponse{
		id:   l.id.string()
		code: l.code
	}
}

pub struct LocaleResponseEnvelope {
pub:
	locale LocaleResponse
}

fn format_locale_response_list(ls []conduit.Locale) []LocaleResponse {
	mut external := []LocaleResponse{len: ls.len}
	for i := 0; i < ls.len; i++ {
		external[i] = format_locale_response(ls[i])
	}
	return external
}

pub struct LocaleResponseListEnvelope {
pub:
	locales []LocaleResponse
	count   i64
	offset  i32
	fetch   i32
}

pub struct CurrencyResponse {
pub:
	code           string
	decimal_digits ?i32 @[json: 'decimalDigits'; omitempty]
}

fn format_currency_response(c conduit.Currency) CurrencyResponse {
	return CurrencyResponse{
		code:           c.code
		decimal_digits: c.decimal_digits
	}
}

pub struct CurrencyResponseEnvelope {
pub:
	currency CurrencyResponse
}

pub struct CurrencyResponseListEnvelope {
pub:
	currencies []CurrencyResponse
	count      i64
	offset     i32
	fetch      i32
}

pub struct CountryResponse {
pub:
	code      string
	region_id string @[json: 'regionId'; omitempty]
}

fn format_country_response(c conduit.Country) CountryResponse {
	mut region_id := ''
	if c.region_id != none {
		region_id = c.region_id.string()
	}

	return CountryResponse{
		code:      c.code
		region_id: region_id
	}
}

pub struct CountryResponseListEnvelope {
pub:
	countries []CountryResponse
	count     i64
	offset    i32
	fetch     i32
}

pub struct StoreResponse {
pub:
	id                        string
	created_at                time.Time @[json: 'createdAt']
	updated_at                time.Time @[json: 'updatedAt']
	name                      string
	default_region_id         string @[json: 'defaultRegionId']
	default_locale_id         string @[json: 'defaultLocaleId']
	default_stock_location_id string @[json: 'defaultStockLocationId']
	default_sales_channel_id  string @[json: 'defaultSalesChannelId']
	locales                   []LocaleResponse
}

fn format_store_response(s conduit.Store) StoreResponse {
	mut locales := []LocaleResponse{len: s.locales.len}
	for i := 0; i < s.locales.len; i++ {
		locales[i] = format_locale_response(s.locales[i])
	}

	return StoreResponse{
		id:                        s.id.string()
		created_at:                s.created_at.Time
		updated_at:                s.updated_at.Time
		name:                      s.name
		default_locale_id:         s.default_locale_id.string()
		default_region_id:         s.default_region_id.string()
		default_stock_location_id: s.default_stock_location_id.string()
		default_sales_channel_id:  s.default_sales_channel_id.string()
		locales:                   locales
	}
}

pub struct StoreResponseEnvelope {
pub:
	store StoreResponse
}

pub struct ImageTranslationResponse {
pub:
	image_id string @[json: 'imageId']
	alt      string
}

fn format_image_translation_response(p []conduit.ImageTranslation) map[string]ImageTranslationResponse {
	mut res := map[string]ImageTranslationResponse{}
	for i := 0; i < p.len; i++ {
		translation := p[i]
		locale_id := translation.locale_id.string()
		res[locale_id] = ImageTranslationResponse{
			image_id: translation.image_id.string()
			alt:      translation.alt
		}
	}
	return res
}

pub struct ProductImageResponse {
pub:
	id           string
	url          string
	image_rank   i32
	product_id   string  @[json: 'productId']
	alt          ?string @[omitempty]
	translations map[string]ImageTranslationResponse @[omitempty]
}

fn format_product_image_response(p conduit.ProductImage) ProductImageResponse {
	return ProductImageResponse{
		id:           p.id.string()
		url:          p.url
		image_rank:   p.image_rank
		product_id:   p.product_id.string()
		alt:          p.alt
		translations: format_image_translation_response(p.translations)
	}
}

pub struct ProductTranslationResponse {
pub:
	product_id  string @[json: 'productId']
	title       string @[omitempty]
	subtitle    string @[omitempty]
	description string @[omitempty]
}

fn format_product_translations(p []conduit.ProductTranslation) map[string]ProductTranslationResponse {
	mut res := map[string]ProductTranslationResponse{}
	for i := 0; i < p.len; i++ {
		translation := p[i]
		locale_id := translation.locale_id.string()
		res[locale_id] = ProductTranslationResponse{
			product_id:  translation.product_id.string()
			title:       translation.title
			subtitle:    translation.subtitle
			description: translation.description
		}
	}
	return res
}

pub struct ProductOptionValueTranslationResponse {
pub:
	option_value_id string @[json: 'optionValueId']
	name            string
}

fn format_product_option_value_translations(p []conduit.ProductOptionValueTranslation) map[string]ProductOptionValueTranslationResponse {
	mut res := map[string]ProductOptionValueTranslationResponse{}
	for i := 0; i < p.len; i++ {
		translation := p[i]
		locale_id := translation.locale_id.string()
		res[locale_id] = ProductOptionValueTranslationResponse{
			option_value_id: translation.option_value_id.string()
			name:            translation.name
		}
	}
	return res
}

pub struct ProductOptionValueResponse {
pub:
	id           string
	option_id    string @[json: 'optionId']
	name         string
	value_rank   i32 @[json: 'valueRank']
	translations map[string]ProductOptionValueTranslationResponse @[omitempty]
}

fn format_product_option_value_response(p conduit.ProductOptionValue) ProductOptionValueResponse {
	return ProductOptionValueResponse{
		id:           p.id.string()
		option_id:    p.option_id.string()
		name:         p.name
		value_rank:   p.value_rank
		translations: format_product_option_value_translations(p.translations)
	}
}

pub struct ProductOptionTranslationResponse {
pub:
	option_id string @[json: 'optionId']
	title     string
}

fn format_product_option_translations(p []conduit.ProductOptionTranslation) map[string]ProductOptionTranslationResponse {
	mut res := map[string]ProductOptionTranslationResponse{}
	for i := 0; i < p.len; i++ {
		translation := p[i]
		locale_id := translation.locale_id.string()
		res[locale_id] = ProductOptionTranslationResponse{
			option_id: translation.product_option_id.string()
			title:     translation.title
		}
	}
	return res
}

pub struct ProductOptionResponse {
pub:
	id           string
	product_id   string @[json: 'productId']
	title        string
	option_rank  i32 @[json: 'optionRank']
	values       []ProductOptionValueResponse
	translations map[string]ProductOptionTranslationResponse @[omitempty]
}

fn format_product_option_response(p conduit.ProductOption) ProductOptionResponse {
	mut values := []ProductOptionValueResponse{len: p.values.len}
	for i := 0; i < p.values.len; i++ {
		values[i] = format_product_option_value_response(p.values[i])
	}

	return ProductOptionResponse{
		id:           p.id.string()
		product_id:   p.product_id.string()
		title:        p.title
		option_rank:  p.option_rank
		values:       values
		translations: format_product_option_translations(p.translations)
	}
}

pub struct PriceResponse {
pub:
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
pub:
	id         string
	created_at time.Time  @[json: 'createdAt']
	updated_at time.Time  @[json: 'updatedAt']
	deleted_at ?time.Time @[json: 'deletedAt'; omitempty]
	rate       f32        @[omitempty]
	code       ?string    @[omitempty]
	name       string
	tax_type   string @[json: 'taxType'; omitempty]
}

fn format_tax_rate_response(t conduit.TaxRate) TaxRateResponse {
	return TaxRateResponse{
		id:         t.id.string()
		created_at: t.created_at.Time
		updated_at: t.updated_at.Time
		deleted_at: format_none_date_time(t.deleted_at)
		rate:       t.rate
		code:       t.code
		name:       t.name
		tax_type:   t.tax_type
	}
}

// VariantPriceResponse represents a regional price of a variant.
// Each variant has one `base_price` for each region, and may have one `original_price` for each region.
// A /store/ consumer may display the original_price in comparison with the base_price (eg: was x, now y).
pub struct VariantPriceResponse {
pub mut:
	currency_code  string @[json: 'currencyCode']
	includes_tax   bool   @[json: 'includesTax']
	original_price i32    @[json: 'originalPrice'; omitempty]
	base_price     i32    @[json: 'basePrice']
}

fn format_variant_price_response(p VariantPrice) VariantPriceResponse {
	return VariantPriceResponse{
		currency_code:  p.currency_code
		includes_tax:   p.includes_tax
		original_price: p.original_price
		base_price:     p.base_price
	}
}

fn format_regional_prices(p []conduit.VariantMoneyAmount) map[string]VariantPriceResponse {
	mut res := map[string]VariantPriceResponse{}
	for i := 0; i < p.len; i++ {
		money_amount := p[i]
		region_id := money_amount.region_id.string()
		if region_id in res {
			if money_amount.is_original {
				res[region_id].original_price = money_amount.amount
				continue
			}

			res[region_id].base_price = money_amount.amount
			continue
		}

		res[region_id] = VariantPriceResponse{
			currency_code: money_amount.currency_code
			includes_tax:  money_amount.includes_tax
		}

		if money_amount.is_original {
			res[region_id].original_price = money_amount.amount
			continue
		}

		res[region_id].base_price = money_amount.amount
	}

	return res
}

pub struct RegionResponse {
pub:
	id                 string
	name               string
	created_at         time.Time         @[json: 'createdAt']
	updated_at         time.Time         @[json: 'updatedAt']
	deleted_at         ?time.Time        @[json: 'deletedAt'; omitempty]
	currency_code      string            @[json: 'currencyCode']
	includes_tax       bool              @[json: 'includesTax']
	gift_cards_taxable bool              @[json: 'giftCardsTaxable']
	automatic_taxes    bool              @[json: 'automaticTaxes']
	tax_rates          []TaxRateResponse @[json: 'taxRates']
}

fn format_region_response(r conduit.Region) RegionResponse {
	mut tax_rates := []TaxRateResponse{len: r.tax_rates.len}
	for i := 0; i < r.tax_rates.len; i++ {
		tax_rates[i] = format_tax_rate_response(r.tax_rates[i])
	}

	return RegionResponse{
		id:                 r.id.string()
		name:               r.name
		created_at:         r.created_at.Time
		updated_at:         r.updated_at.Time
		deleted_at:         format_none_date_time(r.deleted_at)
		currency_code:      r.currency_code
		includes_tax:       r.includes_tax
		gift_cards_taxable: r.gift_cards_taxable
		automatic_taxes:    r.automatic_taxes
		tax_rates:          tax_rates
	}
}

pub struct RegionResponseEnvelope {
pub:
	region RegionResponse
}

pub struct RegionResponseListEnvelope {
pub:
	regions []RegionResponse
	count   i64
	offset  i32
	fetch   i32
}

pub struct InventoryLevelResponse {
pub:
	inventory_item_id string @[json: 'inventoryItemId']
	stock_location_id string @[json: 'stockLocationId']
	stocked_quantity  i32    @[json: 'stockedQuantity']
	reserved_quantity i32    @[json: 'reservedQuantity']
}

fn format_inventory_level_response(v conduit.InventoryLevel) InventoryLevelResponse {
	return InventoryLevelResponse{
		inventory_item_id: v.inventory_item_id.string()
		stock_location_id: v.stock_location_id.string()
		stocked_quantity:  v.stocked_quantity
		reserved_quantity: v.reserved_quantity
	}
}

pub struct InventoryLevelResponseEnvelope {
pub:
	inventory_level InventoryLevelResponse @[json: 'inventoryLevel']
}

pub struct InventoryItemResponse {
pub:
	id                string
	created_at        time.Time                @[json: 'createdAt']
	updated_at        time.Time                @[json: 'updatedAt']
	deleted_at        ?time.Time               @[json: 'deletedAt'; omitempty]
	variant_id        string                   @[json: 'variantId']
	sku               ?string                  @[omitempty]
	origin_country    ?string                  @[json: 'originCountry'; omitempty]
	hs_code           ?string                  @[json: 'hsCode'; omitempty]
	mid_code          ?string                  @[json: 'midCode'; omitempty]
	material          ?string                  @[omitempty]
	weight            ?i32                     @[omitempty]
	length            ?i32                     @[omitempty]
	height            ?i32                     @[omitempty]
	width             ?i32                     @[omitempty]
	requires_shipping bool                     @[json: 'requiresShipping']
	manage_inventory  bool                     @[json: 'manageInventory']
	allow_backorder   bool                     @[json: 'allowBackorder']
	inventory_levels  []InventoryLevelResponse @[json: 'inventoryLevels'; omitempty]
}

fn format_inventory_item_response(v conduit.InventoryItem) InventoryItemResponse {
	mut inventory_levels := []InventoryLevelResponse{len: v.inventory_levels.len}
	for i := 0; i < v.inventory_levels.len; i++ {
		inventory_levels[i] = format_inventory_level_response(v.inventory_levels[i])
	}

	return InventoryItemResponse{
		id:                v.id.string()
		created_at:        v.created_at.Time
		updated_at:        v.updated_at.Time
		deleted_at:        format_none_date_time(v.deleted_at)
		variant_id:        v.variant_id.string()
		sku:               v.sku
		origin_country:    v.origin_country
		hs_code:           v.hs_code
		mid_code:          v.mid_code
		material:          v.material
		weight:            v.weight
		length:            v.length
		height:            v.height
		width:             v.width
		requires_shipping: v.requires_shipping
		manage_inventory:  v.manage_inventory
		allow_backorder:   v.allow_backorder
		inventory_levels:  inventory_levels
	}
}

pub struct VariantResponse {
pub:
	id                 string
	created_at         time.Time                       @[json: 'createdAt']
	updated_at         time.Time                       @[json: 'updatedAt']
	deleted_at         ?time.Time                      @[json: 'deletedAt'; omitempty]
	product_id         string                          @[json: 'productId']
	title              ?string                         @[omitempty]
	barcode            ?string                         @[omitempty]
	ean                ?string                         @[omitempty]
	upc                ?string                         @[omitempty]
	variant_rank       i32                             @[json: 'variantRank']
	metadata           ?string                         @[omitempty]
	image_id           ?string                         @[omitempty]
	option_values      []ProductOptionValueResponse    @[json: 'optionValues']
	regional_prices    map[string]VariantPriceResponse @[json: 'regionalPrices']
	inventory_item     InventoryItemResponse           @[json: 'inventoryItem'; omitempty]
	inventory_quantity i32 @[json: 'inventoryQuantity']
}

fn format_variant_response(v conduit.Variant) VariantResponse {
	mut option_values := []ProductOptionValueResponse{len: v.option_values.len}
	for i := 0; i < v.option_values.len; i++ {
		option_values[i] = format_product_option_value_response(v.option_values[i])
	}

	return VariantResponse{
		id:                 v.id.string()
		created_at:         v.created_at.Time
		updated_at:         v.updated_at.Time
		deleted_at:         format_none_date_time(v.deleted_at)
		product_id:         v.product_id.string()
		title:              v.title
		barcode:            v.barcode
		ean:                v.ean
		upc:                v.upc
		variant_rank:       v.variant_rank
		metadata:           v.metadata
		image_id:           format_none_id(v.image_id)
		inventory_item:     format_inventory_item_response(v.inventory_item)
		inventory_quantity: get_inventory_quantity(v.inventory_item)
		option_values:      option_values
		regional_prices:    format_regional_prices(v.money_amounts)
	}
}

pub struct VariantResponseStore {
pub:
	id                 string
	created_at         time.Time                    @[json: 'createdAt']
	updated_at         time.Time                    @[json: 'updatedAt']
	deleted_at         ?time.Time                   @[json: 'deletedAt'; omitempty]
	product_id         string                       @[json: 'productId']
	title              ?string                      @[omitempty]
	barcode            ?string                      @[omitempty]
	ean                ?string                      @[omitempty]
	upc                ?string                      @[omitempty]
	variant_rank       i32                          @[json: 'variantRank']
	metadata           ?string                      @[omitempty]
	image_id           ?string                      @[omitempty]
	option_values      []ProductOptionValueResponse @[json: 'optionValues'; omitempty]
	inventory_quantity i32 @[json: 'inventoryQuantity']
	purchasable        bool
	price              VariantPriceResponse
}

fn format_variant_response_store(v conduit.Variant, p VariantPrice, product_variants_availability map[string]ProductVariantAvailability) VariantResponseStore {
	product_variant_availability := product_variants_availability[v.id.string()]

	mut option_values := []ProductOptionValueResponse{len: v.option_values.len}
	for i := 0; i < v.option_values.len; i++ {
		option_values[i] = format_product_option_value_response(v.option_values[i])
	}

	return VariantResponseStore{
		id:                 v.id.string()
		created_at:         v.created_at.Time
		updated_at:         v.updated_at.Time
		deleted_at:         format_none_date_time(v.deleted_at)
		product_id:         v.product_id.string()
		title:              v.title
		barcode:            v.barcode
		ean:                v.ean
		upc:                v.upc
		variant_rank:       v.variant_rank
		metadata:           v.metadata
		image_id:           format_none_id(v.image_id)
		inventory_quantity: product_variant_availability.inventory_quantity
		option_values:      option_values
		price:              format_variant_price_response(p)
		purchasable:        product_variant_availability.purchasable
	}
}

pub struct SEOTranslationResponse {
pub:
	seo_id      string
	title       ?string @[omitempty]
	description ?string @[omitempty]
}

fn format_seo_translations(p []conduit.SEOTranslation) map[string]SEOTranslationResponse {
	mut res := map[string]SEOTranslationResponse{}
	for i := 0; i < p.len; i++ {
		translation := p[i]
		locale_id := translation.locale_id.string()
		res[locale_id] = SEOTranslationResponse{
			seo_id:      translation.seo_id.string()
			title:       translation.title
			description: translation.description
		}
	}
	return res
}

pub struct SEOResponse {
pub:
	title        ?string @[omitempty]
	description  ?string @[omitempty]
	translations map[string]SEOTranslationResponse @[omitempty]
}

fn format_seo_response(p conduit.SEO) SEOResponse {
	return SEOResponse{
		title:        p.title
		description:  p.description
		translations: format_seo_translations(p.translations)
	}
}

pub struct SEOResponseStore {
pub:
	title       ?string @[omitempty]
	description ?string @[omitempty]
}

pub struct CategoryTranslationResponse {
pub:
	category_id string @[json: 'productCategoryId']
	name        string @[omitempty]
	description string @[omitempty]
}

fn format_category_translations(p []conduit.CategoryTranslation) map[string]CategoryTranslationResponse {
	mut res := map[string]CategoryTranslationResponse{}
	for i := 0; i < p.len; i++ {
		translation := p[i]
		locale_id := translation.locale_id.string()
		res[locale_id] = CategoryTranslationResponse{
			category_id: translation.category_id.string()
			name:        string_value(translation.name)
			description: string_value(translation.description)
		}
	}
	return res
}

pub struct CategoryResponse {
pub:
	id                 string
	created_at         time.Time  @[json: 'createdAt']
	updated_at         time.Time  @[json: 'updatedAt']
	deleted_at         ?time.Time @[json: 'deletedAt'; omitempty]
	handle             string
	parent_category_id ?string @[json: 'parentCategoryId'; omitempty]
	is_active          bool    @[json: 'isActive']
	is_internal        bool    @[json: 'isInternal']
	metadata           ?string @[omitempty]
	name               string
	description        ?string     @[omitempty]
	seo                SEOResponse @[omitempty]
	translations       map[string]CategoryTranslationResponse @[omitempty]
}

fn format_category_response(p conduit.Category) CategoryResponse {
	return CategoryResponse{
		id:                 p.id.string()
		created_at:         p.created_at.Time
		updated_at:         p.updated_at.Time
		deleted_at:         format_none_date_time(p.deleted_at)
		handle:             p.handle
		parent_category_id: format_none_id(p.parent_category_id)
		is_active:          p.is_active
		is_internal:        p.is_internal
		metadata:           p.metadata
		name:               p.name
		description:        p.description
		translations:       format_category_translations(p.translations)
		seo:                format_seo_response(p.seo.SEO)
	}
}

pub struct CategoryResponseEnvelope {
pub:
	category CategoryResponse
}

pub struct CategoryResponseListEnvelope {
pub:
	categories []CategoryResponse
	count      i64
	offset     i32
	fetch      i32
}

pub struct CategoryResponseStore {
pub:
	id                 string
	created_at         time.Time @[json: 'createdAt']
	updated_at         time.Time @[json: 'updatedAt']
	handle             string
	parent_category_id ?string          @[json: 'parentCategoryId'; omitempty]
	metadata           ?string          @[omitempty]
	name               string           @[omitempty]
	description        ?string          @[omitempty]
	seo                SEOResponseStore @[omitempty]
}

fn format_category_response_store(p conduit.Category, locale_context LocaleContext) CategoryResponseStore {
	mut seo_title := p.seo.title
	mut seo_description := p.seo.description

	if locale_id := locale_context.locale_id {
		for i := 0; i < p.seo.translations.len; i++ {
			translation := p.seo.translations[i]
			if translation.locale_id.string() != locale_id.string() {
				continue
			}

			if title := translation.title {
				seo_title = title
			}

			if description := translation.description {
				seo_description = description
			}
		}
	}

	seo := SEOResponseStore{
		title:       seo_title
		description: seo_description
	}

	return CategoryResponseStore{
		id:                 p.id.string()
		created_at:         p.created_at.Time
		updated_at:         p.updated_at.Time
		handle:             p.handle
		parent_category_id: format_none_id(p.parent_category_id)
		metadata:           p.metadata
		name:               p.name
		description:        p.description
		seo:                seo
	}
}

pub struct CategoryResponseStoreEnvelope {
pub:
	category CategoryResponseStore
}

pub struct CategoryResponseStoreListEnvelope {
pub:
	categories []CategoryResponseStore
	count      i64
	offset     i32
	fetch      i32
}

pub struct VariantResponseEnvelope {
pub:
	variant VariantResponse
}

pub struct SalesChannelResponse {
pub:
	id          string
	created_at  time.Time  @[json: 'createdAt']
	updated_at  time.Time  @[json: 'updatedAt']
	deleted_at  ?time.Time @[json: 'deletedAt'; omitempty]
	name        string
	description string @[omitempty]
	is_disabled bool   @[json: 'isDisabled']
}

fn format_sales_channel_response(v conduit.SalesChannel) SalesChannelResponse {
	return SalesChannelResponse{
		id:          v.id.string()
		created_at:  v.created_at.Time
		updated_at:  v.updated_at.Time
		deleted_at:  format_none_date_time(v.deleted_at)
		name:        v.name
		description: v.description
		is_disabled: v.is_disabled
	}
}

pub struct SalesChannelResponseEnvelope {
pub:
	sales_channels []SalesChannelResponse @[json: 'salesChannels']
	count          i64
	offset         i32
	fetch          i32
}

pub struct ProductResponse {
pub:
	id                string
	created_at        time.Time  @[json: 'createdAt']
	updated_at        time.Time  @[json: 'updatedAt']
	deleted_at        ?time.Time @[json: 'deletedAt'; omitempty]
	handle            string
	is_giftcard       bool @[json: 'isGiftcard']
	status            string
	type_id           ?string @[json: 'typeId'; omitempty]
	discountable      bool
	metadata          ?string @[omitempty]
	title             string
	subtitle          ?string                               @[omitempty]
	description       ?string                               @[omitempty]
	category_ids      []string                              @[json: 'categoryIds'; omitempty]
	thumbnail         ProductImageResponse                  @[omitempty]
	images            []ProductImageResponse                @[omitempty]
	options           []ProductOptionResponse               @[omitempty]
	variants          []VariantResponse                     @[omitempty]
	sales_channel_ids []string                              @[json: 'salesChannels']
	translations      map[string]ProductTranslationResponse @[omitempty]
	seo               SEOResponse @[omitempty]
	// tags         []Tag                       @[omitempty] // return ids only
}

fn format_product_response(p conduit.Product) ProductResponse {
	mut thumbnail := ProductImageResponse{}
	mut images := []ProductImageResponse{len: p.images.len}
	for i := 0; i < p.images.len; i++ {
		image := p.images[i]
		external_image := format_product_image_response(image)
		images[i] = external_image
		if thumbnail_id := p.thumbnail_id {
			if thumbnail_id == image.id {
				thumbnail = external_image
			}
		}
	}

	mut options := []ProductOptionResponse{len: p.options.len}
	for i := 0; i < p.options.len; i++ {
		options[i] = format_product_option_response(p.options[i])
	}

	mut variants := []VariantResponse{len: p.variants.len}
	for i := 0; i < p.variants.len; i++ {
		variants[i] = format_variant_response(p.variants[i])
	}

	return ProductResponse{
		id:                p.id.string()
		created_at:        p.created_at.Time
		updated_at:        p.updated_at.Time
		deleted_at:        format_none_date_time(p.deleted_at)
		handle:            p.handle
		is_giftcard:       p.is_giftcard
		status:            p.status
		type_id:           format_none_id(p.type_id)
		discountable:      p.discountable
		metadata:          p.metadata
		title:             p.title
		subtitle:          p.subtitle
		description:       p.description
		thumbnail:         thumbnail
		images:            images
		options:           options
		variants:          variants
		category_ids:      format_array_id(p.category_ids)
		sales_channel_ids: format_array_id(p.sales_channels_ids)
		translations:      format_product_translations(p.translations)
		seo:               format_seo_response(p.seo.SEO)
		// tags:          tags
	}
}

pub struct ProductResponseEnvelope {
pub:
	product ProductResponse
}

pub struct ProductResponseListEnvelope {
pub:
	products []ProductResponse
	count    i64
	offset   i32
	fetch    i32
}

pub struct ProductResponseStore {
pub:
	id           string
	created_at   time.Time  @[json: 'createdAt']
	updated_at   time.Time  @[json: 'updatedAt']
	deleted_at   ?time.Time @[json: 'deletedAt'; omitempty]
	handle       string
	is_giftcard  bool @[json: 'isGiftcard']
	status       string
	type_id      ?string @[json: 'typeId'; omitempty]
	discountable bool
	metadata     ?string @[omitempty]
	title        string
	subtitle     ?string                 @[omitempty]
	description  ?string                 @[omitempty]
	category_ids []string                @[json: 'categoryIds'; omitempty]
	thumbnail    ProductImageResponse    @[omitempty]
	images       []ProductImageResponse  @[omitempty]
	options      []ProductOptionResponse @[omitempty]
	variants     []VariantResponseStore  @[omitempty]
	seo          SEOResponseStore        @[omitempty]
	// tags         []Tag                       @[omitempty]
}

fn format_product_response_store(p conduit.Product, pctx PriceContext, default_region_id ID, product_variants_availability map[string]ProductVariantAvailability, locale_context LocaleContext) ProductResponseStore {
	mut thumbnail := ProductImageResponse{}
	mut images := []ProductImageResponse{len: p.images.len}
	for i := 0; i < p.images.len; i++ {
		image := p.images[i]
		external_image := format_product_image_response(image)
		images[i] = external_image
		if thumbnail_id := p.thumbnail_id {
			if thumbnail_id == image.id {
				thumbnail = external_image
			}
		}
	}

	mut options := []ProductOptionResponse{len: p.options.len}
	for i := 0; i < p.options.len; i++ {
		options[i] = format_product_option_response(p.options[i])
	}

	mut variants := []VariantResponseStore{len: p.variants.len}
	for i := 0; i < p.variants.len; i++ {
		variant := p.variants[i]
		prices := calculate_price(variant, default_region_id, pctx, 1)
		variants[i] = format_variant_response_store(variant, prices, product_variants_availability)
	}

	mut seo_title := p.seo.title
	mut seo_description := p.seo.description

	if locale_id := locale_context.locale_id {
		for i := 0; i < p.seo.translations.len; i++ {
			translation := p.seo.translations[i]
			if translation.locale_id.string() != locale_id.string() {
				continue
			}

			if title := translation.title {
				seo_title = title
			}

			if description := translation.description {
				seo_description = description
			}
		}
	}

	seo := SEOResponseStore{
		title:       seo_title
		description: seo_description
	}

	return ProductResponseStore{
		id:           p.id.string()
		created_at:   p.created_at.Time
		updated_at:   p.updated_at.Time
		deleted_at:   format_none_date_time(p.deleted_at)
		handle:       p.handle
		is_giftcard:  p.is_giftcard
		status:       p.status
		type_id:      format_none_id(p.type_id)
		discountable: p.discountable
		metadata:     p.metadata
		title:        p.title
		subtitle:     p.subtitle
		description:  p.description
		thumbnail:    thumbnail
		images:       images
		options:      options
		variants:     variants
		category_ids: format_array_id(p.category_ids)
		seo:          seo
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
	fetch    i32
}

pub struct UploadsUploadResponseEnvelope {
	uploads []providers.BlobFileData
}

pub struct UploadsUploadOneResponseEnvelope {
	upload providers.BlobFileData
}

pub struct UploadsDeleteResponse {
	id      string
	deleted bool
}

pub struct StockLocationResponse {
	id         string
	created_at time.Time  @[json: 'createdAt']
	updated_at time.Time  @[json: 'updatedAt']
	deleted_at ?time.Time @[json: 'deletedAt'; omitempty]
	name       string
}

fn format_stock_location_response(p conduit.StockLocation) StockLocationResponse {
	return StockLocationResponse{
		id:         p.id.string()
		created_at: p.created_at.Time
		updated_at: p.updated_at.Time
		deleted_at: format_none_date_time(p.deleted_at)
		name:       p.name
	}
}

pub struct StockLocationResponseListEnvelope {
	stock_locations []StockLocationResponse @[json: 'stockLocations']
	count           i64
	offset          i32
	fetch           i32
}

pub struct StockLocationResponseEnvelope {
	stock_location StockLocationResponse @[json: 'stockLocation']
}
