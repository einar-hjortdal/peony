module peony

import time
import veb

// TODO eliminate: always return created/updated resource
pub struct PeonySuccess {
pub:
	success bool
}

fn success(mut ctx Context) veb.Result {
	return ctx.json(PeonySuccess{
		success: true
	})
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

pub struct UserResponse {
pub:
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

pub struct UserResponseEnvelope {
pub:
	user UserResponse
}

// users: the list of users
// count: the total count of items.
// offset: the number of items skipped before retrieving the returned items.
// fetch: the maximum number of items returned.
pub struct UserListResponseEnvelope {
pub:
	users  []UserResponse
	count  i64
	offset i32
	fetch  i32 @[omitempty]
}

pub struct LocaleResponse {
pub:
	id   string
	code string
}

fn format_locale_response(l Locale) LocaleResponse {
	return LocaleResponse{
		id:   l.id
		code: l.code
	}
}

pub struct LocaleResponseEnvelope {
pub:
	locale LocaleResponse
}

pub struct LocaleResponseListEnvelope {
pub:
	locales []LocaleResponse
	count   i64
	offset  i32
	fetch   i32 @[omitempty]
}

pub struct CurrencyResponse {
pub:
	code           string
	decimal_digits i32 @[json: 'decimalDigits'; omitempty]
}

fn format_currency_response(c Currency) CurrencyResponse {
	return CurrencyResponse{
		code:           c.code
		decimal_digits: c.decimal_digits.value
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
	fetch      i32 @[omitempty]
}

pub struct CountryResponse {
pub:
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

pub struct CountryResponseListEnvelope {
pub:
	countries []CountryResponse
	count     i64
	offset    i32
	fetch     i32 @[omitempty]
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

fn format_store_response(s Store) StoreResponse {
	mut locales := []LocaleResponse{len: s.locales.len}
	for i := 0; i < s.locales.len; i++ {
		locales[i] = format_locale_response(s.locales[i])
	}

	return StoreResponse{
		id:                        s.id
		created_at:                s.created_at.Time
		updated_at:                s.updated_at.Time
		name:                      s.name
		default_locale_id:         s.default_locale_id
		default_region_id:         s.default_region_id
		default_stock_location_id: s.default_stock_location_id
		default_sales_channel_id:  s.default_sales_channel_id
		locales:                   locales
	}
}

pub struct StoreResponseEnvelope {
pub:
	store StoreResponse
}

pub struct ImageTranslationResponse {
pub:
	image_id  string @[json: 'imageId']
	locale_id string @[json: 'localeId']
	alt       string
}

fn format_image_translation_response(p ImageTranslation) ImageTranslationResponse {
	return ImageTranslationResponse{
		image_id:  p.image_id
		locale_id: p.locale_id
		alt:       p.alt
	}
}

pub struct ProductImageResponse {
pub:
	id           string
	url          string
	product_id   string                     @[json: 'productId']
	alt          string                     @[omitempty]
	translations []ImageTranslationResponse @[omitempty]
}

fn format_product_image_response(p ProductImage) ProductImageResponse {
	mut translations := []ImageTranslationResponse{}
	if p.translations.len > 0 {
		translations = []ImageTranslationResponse{len: p.translations.len}
		for i := 0; i < p.translations.len; i++ {
			translations[i] = format_image_translation_response(p.translations[i])
		}
	}

	return ProductImageResponse{
		id:           p.id
		url:          p.url
		product_id:   p.product_id
		alt:          p.alt.value
		translations: translations
	}
}

pub struct ProductTranslationResponse {
pub:
	product_id  string @[json: 'productId']
	locale_id   string @[json: 'localeId']
	title       string @[omitempty]
	subtitle    string @[omitempty]
	description string @[omitempty]
}

fn format_product_translation_response(p ProductTranslation) ProductTranslationResponse {
	return ProductTranslationResponse{
		product_id:  p.product_id
		locale_id:   p.locale_id
		title:       p.title
		subtitle:    p.subtitle
		description: p.description
	}
}

pub struct ProductOptionValueTranslationResponse {
pub:
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
pub:
	id           string
	option_id    string @[json: 'optionId']
	name         string
	value_rank   i32 @[json: 'valueRank']
	translations []ProductOptionValueTranslationResponse @[omitempty]
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
		value_rank:   p.value_rank
		translations: translations
	}
}

pub struct ProductOptionTranslationResponse {
pub:
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
pub:
	id           string
	product_id   string @[json: 'productId']
	title        string
	option_rank  i32 @[json: 'optionRank']
	values       []ProductOptionValueResponse
	translations []ProductOptionTranslationResponse @[omitempty]
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
		title:        p.title
		option_rank:  p.option_rank
		values:       values
		translations: translations
	}
}

pub struct PriceListPriceResponse {
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

// VariantPriceResponseStore represents the price of a variant.
// This is calculated utilizing the context of the request coming from the /store/ endpoints.
pub struct VariantPriceResponse {
pub:
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

// VariantMoneyAmountResponse represents a regional price of a variant.
// Each variant has one price for each region, and may have one additional price for each region.
// The mandatory price is the `base_price` and the optional additional price is the `original_price`.
// A /store/ consumer may display the original_price in comparison with the base_price (eg: was x, now y).
pub struct VariantMoneyAmountResponse {
pub:
	region_id     string @[json: 'regionId']
	currency_code string @[json: 'currencyCode']
	is_original   bool   @[json: 'isOriginal'; omitempty]
	amount        i32
}

fn format_variant_money_amount_response(p VariantMoneyAmount) VariantMoneyAmountResponse {
	return VariantMoneyAmountResponse{
		region_id:     p.region_id
		currency_code: p.currency_code
		is_original:   p.is_original
		amount:        p.amount
	}
}

pub struct RegionResponse {
pub:
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

fn format_region_response(r Region) RegionResponse {
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

pub struct RegionResponseEnvelope {
pub:
	region RegionResponse
}

pub struct RegionResponseListEnvelope {
pub:
	regions []RegionResponse
	count   i64
	offset  i32
	fetch   i32 @[omitempty]
}

pub struct InventoryLevelResponse {
pub:
	inventory_item_id string @[json: 'inventoryItemId']
	stock_location_id string @[json: 'stockLocationId']
	stocked_quantity  i32    @[json: 'stockedQuantity']
	reserved_quantity i32    @[json: 'reservedQuantity']
}

fn format_inventory_level_response(v InventoryLevel) InventoryLevelResponse {
	return InventoryLevelResponse{
		inventory_item_id: v.inventory_item_id
		stock_location_id: v.stock_location_id
		stocked_quantity:  v.stocked_quantity
		reserved_quantity: v.reserved_quantity
	}
}

pub struct InventoryItemResponse {
pub:
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

fn format_inventory_item_response(v InventoryItem) InventoryItemResponse {
	mut inventory_levels := []InventoryLevelResponse{len: v.inventory_levels.len}
	for i := 0; i < v.inventory_levels.len; i++ {
		inventory_levels[i] = format_inventory_level_response(v.inventory_levels[i])
	}

	return InventoryItemResponse{
		id:                v.id
		created_at:        v.created_at.Time
		updated_at:        v.updated_at.Time
		deleted_at:        v.deleted_at.value.Time
		variant_id:        v.variant_id
		sku:               v.sku.value
		origin_country:    v.origin_country.value
		hs_code:           v.hs_code.value
		mid_code:          v.mid_code.value
		material:          v.material.value
		weight:            v.weight.value
		length:            v.length.value
		height:            v.height.value
		width:             v.width.value
		requires_shipping: v.requires_shipping
		manage_inventory:  v.manage_inventory
		allow_backorder:   v.allow_backorder
		inventory_levels:  inventory_levels
	}
}

pub struct VariantResponse {
pub:
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
	money_amounts      []VariantMoneyAmountResponse @[json: 'moneyAmounts']
	inventory_item     InventoryItemResponse        @[json: 'inventoryItem'; omitempty]
	inventory_quantity i32 @[json: 'inventoryQuantity']
}

fn format_variant_response(v ProductVariant) VariantResponse {
	mut option_values := []ProductOptionValueResponse{len: v.option_values.len}
	for i := 0; i < v.option_values.len; i++ {
		option_values[i] = format_product_option_value_response(v.option_values[i])
	}

	mut money_amounts := []VariantMoneyAmountResponse{len: v.money_amounts.len}
	for i := 0; i < v.money_amounts.len; i++ {
		ma := v.money_amounts[i]
		money_amounts[i] = format_variant_money_amount_response(ma)
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
pub:
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
	price              VariantPriceResponse
}

fn format_variant_response_store(v ProductVariant, p VariantPrice, product_variants_availability map[string]ProductVariantAvailability) VariantResponseStore {
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
		price:              format_variant_price_response(p)
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
pub:
	seo_id      string
	locale_id   string @[json: 'localeId']
	title       string @[omitempty]
	description string @[omitempty]
}

fn format_seo_translation_response(t SEOTranslation) SEOTranslationResponse {
	return SEOTranslationResponse{
		seo_id:      t.seo_id
		locale_id:   t.locale_id
		title:       t.title.value
		description: t.description.value
	}
}

pub struct SEOResponse {
pub:
	title       string @[omitempty]
	description string @[omitempty]
pub mut:
	translations []SEOTranslationResponse @[omitempty]
}

pub struct SEOResponseStore {
pub:
	title       string @[omitempty]
	description string @[omitempty]
}

pub struct CategoryTranslationResponse {
pub:
	category_id string @[json: 'productCategoryId']
	locale_id   string @[json: 'localeId']
	name        string @[omitempty]
	description string @[omitempty]
}

pub struct CategoryResponse {
pub:
	id                 string
	created_at         time.Time @[json: 'createdAt']
	updated_at         time.Time @[json: 'updatedAt']
	deleted_at         time.Time @[json: 'deletedAt'; omitempty]
	handle             string
	parent_category_id string                        @[json: 'parentCategoryId'; omitempty]
	is_active          bool                          @[json: 'isActive']
	is_internal        bool                          @[json: 'isInternal']
	metadata           string                        @[omitempty]
	name               string                        @[omitempty]
	description        string                        @[omitempty]
	translations       []CategoryTranslationResponse @[omitempty]
	seo                SEOResponse                   @[omitempty]
}

fn format_category_response(p Category) CategoryResponse {
	mut tr := []CategoryTranslationResponse{len: p.translations.len}
	for i := 0; i < p.translations.len; i++ {
		translation := p.translations[i]
		tr[i] = CategoryTranslationResponse{
			category_id: translation.category_id
			locale_id:   translation.locale_id
			name:        translation.name.value
			description: translation.description.value
		}
	}

	mut seo_translations := []SEOTranslationResponse{len: p.seo.translations.len}
	for i := 0; i < p.seo.translations.len; i++ {
		translation := p.seo.translations[i]
		seo_translations[i] = format_seo_translation_response(translation)
	}

	seo := SEOResponse{
		title:        p.seo.title.value
		description:  p.seo.description.value
		translations: seo_translations
	}

	return CategoryResponse{
		id:                 p.id
		created_at:         p.created_at.Time
		updated_at:         p.updated_at.Time
		deleted_at:         p.deleted_at.value.Time
		handle:             p.handle
		parent_category_id: p.parent_category_id
		is_active:          p.is_active
		is_internal:        p.is_internal
		metadata:           p.metadata.value
		name:               p.name
		description:        p.description.value
		translations:       tr
		seo:                seo
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
	fetch      i32 @[omitempty]
}

pub struct CategoryResponseStore {
pub:
	id                 string
	created_at         time.Time @[json: 'createdAt']
	updated_at         time.Time @[json: 'updatedAt']
	handle             string
	parent_category_id string           @[json: 'parentCategoryId'; omitempty]
	metadata           string           @[omitempty]
	name               string           @[omitempty]
	description        string           @[omitempty]
	seo                SEOResponseStore @[omitempty]
}

fn format_category_response_store(p Category, locale_id string) CategoryResponseStore {
	mut seo := SEOResponseStore{
		title:       p.seo.title.value
		description: p.seo.description.value
	}

	if locale_id != '' {
		for i := 0; i < p.seo.translations.len; i++ {
			translation := p.seo.translations[i]
			if translation.locale_id != locale_id {
				continue
			}

			if !translation.title.is_null {
				seo = SEOResponseStore{
					title:       translation.title.value
					description: seo.description
				}
			}

			if !translation.description.is_null {
				seo = SEOResponseStore{
					title:       seo.title
					description: translation.description.value
				}
			}
		}
	}

	return CategoryResponseStore{
		id:                 p.id
		created_at:         p.created_at.Time
		updated_at:         p.updated_at.Time
		handle:             p.handle
		parent_category_id: p.parent_category_id
		metadata:           p.metadata.value
		name:               p.name
		description:        p.description.value
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
	fetch      i32 @[omitempty]
}

pub struct VariantResponseEnvelope {
pub:
	variant VariantResponse
}

pub struct SalesChannelResponse {
pub:
	id          string
	created_at  time.Time @[json: 'createdAt']
	updated_at  time.Time @[json: 'updatedAt']
	deleted_at  time.Time @[json: 'deletedAt'; omitempty]
	name        string
	description string @[omitempty]
	is_disabled bool   @[json: 'isDisabled']
}

pub struct SalesChannelResponseEnvelope {
pub:
	sales_channels []SalesChannelResponse @[json: 'salesChannels']
	count          i64
	offset         i32
	fetch          i32 @[omitempty]
}

pub struct ProductResponse {
pub:
	id                string
	created_at        time.Time @[json: 'createdAt']
	updated_at        time.Time @[json: 'updatedAt']
	deleted_at        time.Time @[json: 'deletedAt'; omitempty]
	handle            string
	is_giftcard       bool @[json: 'isGiftcard']
	status            string
	type_id           string @[json: 'typeId'; omitempty]
	discountable      bool
	metadata          string @[omitempty]
	title             string
	subtitle          string                       @[omitempty]
	description       string                       @[omitempty]
	category_ids      []string                     @[json: 'categoryIds'; omitempty]
	thumbnail         ProductImageResponse         @[omitempty]
	images            []ProductImageResponse       @[omitempty]
	options           []ProductOptionResponse      @[omitempty]
	variants          []VariantResponse            @[omitempty]
	sales_channel_ids []string                     @[json: 'salesChannels']
	translations      []ProductTranslationResponse @[omitempty]
	seo               SEOResponse                  @[omitempty]
	// tags         []Tag                       @[omitempty] // return ids only
}

fn format_product_response(p Product) ProductResponse {
	mut thumbnail := ProductImageResponse{}
	mut images := []ProductImageResponse{len: p.images.len}
	for i := 0; i < p.images.len; i++ {
		image := p.images[i]
		external_image := format_product_image_response(image)
		images[i] = external_image
		if p.thumbnail_id != '' && p.thumbnail_id == image.id {
			thumbnail = external_image
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

	mut translations := []ProductTranslationResponse{len: p.translations.len}
	for i := 0; i < p.translations.len; i++ {
		translations[i] = format_product_translation_response(p.translations[i])
	}

	mut seo_translations := []SEOTranslationResponse{len: p.seo.translations.len}
	for i := 0; i < p.seo.translations.len; i++ {
		translation := p.seo.translations[i]
		seo_translations[i] = format_seo_translation_response(translation)
	}

	seo := SEOResponse{
		title:        p.seo.title.value
		description:  p.seo.description.value
		translations: seo_translations
	}

	return ProductResponse{
		id:                p.id
		created_at:        p.created_at.Time
		updated_at:        p.updated_at.Time
		deleted_at:        p.deleted_at.value.Time
		handle:            p.handle
		is_giftcard:       p.is_giftcard
		status:            p.status
		type_id:           p.type_id
		discountable:      p.discountable
		metadata:          p.metadata.value
		title:             p.title
		subtitle:          p.subtitle.value
		description:       p.description.value
		thumbnail:         thumbnail
		images:            images
		options:           options
		variants:          variants
		category_ids:      p.category_ids
		sales_channel_ids: p.sales_channels_ids
		translations:      translations
		seo:               seo
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
	fetch    i32 @[omitempty]
}

pub struct ProductResponseStore {
pub:
	id           string
	created_at   time.Time @[json: 'createdAt']
	updated_at   time.Time @[json: 'updatedAt']
	deleted_at   time.Time @[json: 'deletedAt'; omitempty]
	handle       string
	is_giftcard  bool @[json: 'isGiftcard']
	status       string
	type_id      string @[json: 'typeId'; omitempty]
	discountable bool
	metadata     string @[omitempty]
	title        string
	subtitle     string                  @[omitempty]
	description  string                  @[omitempty]
	category_ids []string                @[json: 'categoryIds'; omitempty]
	thumbnail    ProductImageResponse    @[omitempty]
	images       []ProductImageResponse  @[omitempty]
	options      []ProductOptionResponse @[omitempty]
	variants     []VariantResponseStore  @[omitempty]
	seo          SEOResponseStore        @[omitempty]
	// tags         []Tag                       @[omitempty]
}

// note: locale_id is derived from pctx.region_id
fn format_product_response_store(p Product, pctx PriceContext, product_variants_availability map[string]ProductVariantAvailability, locale_id string) ProductResponseStore {
	mut thumbnail := ProductImageResponse{}
	mut images := []ProductImageResponse{len: p.images.len}
	for i := 0; i < p.images.len; i++ {
		image := p.images[i]
		external_image := format_product_image_response(image)
		images[i] = external_image
		if p.thumbnail_id != '' && p.thumbnail_id == image.id {
			thumbnail = external_image
		}
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

	mut seo := SEOResponseStore{
		title:       p.seo.title.value
		description: p.seo.description.value
	}

	if locale_id != '' {
		for i := 0; i < p.seo.translations.len; i++ {
			translation := p.seo.translations[i]
			if translation.locale_id != locale_id {
				continue
			}

			if !translation.title.is_null {
				seo = SEOResponseStore{
					title:       translation.title.value
					description: seo.description
				}
			}

			if !translation.description.is_null {
				seo = SEOResponseStore{
					title:       seo.title
					description: translation.description.value
				}
			}
		}
	}

	// TODO tags

	return ProductResponseStore{
		id:           p.id
		created_at:   p.created_at.Time
		updated_at:   p.updated_at.Time
		deleted_at:   p.deleted_at.value.Time
		handle:       p.handle
		is_giftcard:  p.is_giftcard
		status:       p.status
		type_id:      p.type_id
		discountable: p.discountable
		metadata:     p.metadata.value
		title:        p.title
		subtitle:     p.subtitle.value
		description:  p.description.value
		thumbnail:    thumbnail
		images:       images
		options:      options
		variants:     variants
		category_ids: p.category_ids
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

pub struct StockLocationResponseEnvelope {
	stock_location StockLocationResponse @[json: 'stockLocation']
}
