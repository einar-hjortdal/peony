module peony

pub struct AuthRequest {
pub:
	email    string
	password string
}

pub struct StoreRequest {
pub:
	name                      ?string
	default_locale_id         ?string   @[json: 'defaultLocaleId']
	default_region_id         ?string   @[json: 'defaultRegionId']
	default_stock_location_id ?string   @[json: 'defaultStockLocationId']
	default_sales_channel_id  ?string   @[json: 'defaultSalesChannelId']
	locale_ids                ?[]string @[json: 'localeIds']
	currency_codes            ?[]string @[json: 'currencyCodes']
}

struct StoreRequestHygienised {
	name                          ?string
	default_locale_id             ?string
	default_locale_id_bin         []u8
	default_region_id             ?string
	default_region_id_bin         []u8
	default_stock_location_id     ?string
	default_stock_location_id_bin []u8
	default_sales_channel_id      ?string
	default_sales_channel_id_bin  []u8
	locale_ids                    ?[]string
	locale_ids_bin                [][]u8
	currency_codes                ?[]string
}

fn hygienise_store_request(p StoreRequest) !StoreRequestHygienised {
	default_locale_id_bin := option_id_string_to_id_bin(p.default_locale_id) or {
		return new_internal_error(error_id_invalid, 'default_locale_id')
	}

	default_region_id_bin := option_id_string_to_id_bin(p.default_region_id) or {
		return new_internal_error(error_id_invalid, 'default_region_id')
	}

	default_stock_location_id_bin := option_id_string_to_id_bin(p.default_stock_location_id) or {
		return new_internal_error(error_id_invalid, 'default_stock_location_id')
	}

	locale_ids_bin := option_array_id_string_to_array_id_bin(p.locale_ids) or {
		return new_internal_error(error_id_invalid, 'locale_id')
	}

	default_sales_channel_id_bin := option_id_string_to_id_bin(p.default_sales_channel_id) or {
		return new_internal_error(error_id_invalid, 'default_sales_channel_id')
	}

	return StoreRequestHygienised{
		name:                          p.name
		default_locale_id:             p.default_locale_id
		default_locale_id_bin:         default_locale_id_bin
		default_region_id:             p.default_region_id
		default_region_id_bin:         default_region_id_bin
		default_stock_location_id:     p.default_stock_location_id
		default_stock_location_id_bin: default_stock_location_id_bin
		default_sales_channel_id:      p.default_sales_channel_id
		default_sales_channel_id_bin:  default_sales_channel_id_bin
		locale_ids:                    p.locale_ids
		locale_ids_bin:                locale_ids_bin
		currency_codes:                p.currency_codes
	}
}

pub struct SalesChannelRequest {
pub:
	name        string
	description ?string
	is_disabled ?bool @[json: 'isDisabled']
}

pub struct SalesChannelUpdateRequest {
pub:
	name        ?string
	description ?string
	is_disabled ?bool @[json: 'isDisabled']
}

pub struct ImageRequest {
pub:
	url          string
	translations ?[]ImageTranslationRequest
}

struct ImageRequestHygienised {
	url string
mut:
	translations ?[]ImageTranslationRequestHygienised
}

fn (p ImageRequest) hygienise() !ImageRequestHygienised {
	mut image := ImageRequestHygienised{
		url: p.url
	}

	if translations := p.translations {
		mut itrh := []ImageTranslationRequestHygienised{len: translations.len}
		for i := 0; i < translations.len; i++ {
			itrh[i] = translations[i].hygienise()!
		}
		image.translations = itrh
	}
	return image
}

pub struct UserCreateRequest {
pub:
	email      string
	password   string
	first_name ?string @[json: 'firstName']
	last_name  ?string @[json: 'lastName']
	role       ?string
	image      ?ImageRequest
	metadata   ?string @[raw]
}

pub struct UserUpdateRequest {
pub:
	email      ?string
	first_name ?string @[json: 'firstName']
	last_name  ?string @[json: 'lastName']
	role       ?string
	image      ?ImageRequest
	metadata   ?string @[raw]
}

pub struct ImageTranslationRequest {
pub:
	locale_id string @[json: 'localeId']
	alt       string
}

struct ImageTranslationRequestHygienised {
	locale_id     string
	locale_id_bin []u8
	alt           string
}

fn (i ImageTranslationRequest) hygienise() !ImageTranslationRequestHygienised {
	locale_id_bin := id_string_to_bin(i.locale_id) or {
		return new_internal_error(error_id_invalid, 'locale_id')
	}

	if i.alt == '' {
		return new_internal_error(error_empty_field, 'alt')
	}

	return ImageTranslationRequestHygienised{
		locale_id:     i.locale_id
		locale_id_bin: locale_id_bin
		alt:           i.alt
	}
}

pub struct ProductTranslationRequest {
pub:
	locale_id   string @[json: 'localeId']
	title       ?string
	subtitle    ?string
	description ?string
}

struct ProductTranslationRequestHygienised {
	locale_id     string
	locale_id_bin []u8
	title         ?string
	subtitle      ?string
	description   ?string
}

fn hygienise_product_translation_request(p ProductTranslationRequest) !ProductTranslationRequestHygienised {
	locale_id_bin := id_string_to_bin(p.locale_id) or {
		return new_internal_error(error_id_invalid, 'locale_id')
	}

	return ProductTranslationRequestHygienised{
		locale_id:     p.locale_id
		locale_id_bin: locale_id_bin
		title:         p.title
		subtitle:      p.subtitle
		description:   p.description
	}
}

pub struct ProductOptionValueTranslationRequest {
pub:
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

pub struct ProductOptionValueRequest {
pub:
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

pub struct ProductOptionTranslationRequest {
pub:
	title     string
	locale_id string @[json: 'localeId']
}

struct ProductOptionTranslationRequestHygienised {
	title         string
	locale_id     string
	locale_id_bin []u8
}

fn (p ProductOptionTranslationRequest) hygienise() !ProductOptionTranslationRequestHygienised {
	locale_id_bin := id_string_to_bin(p.locale_id) or {
		return new_internal_error(error_id_invalid, 'locale_id')
	}
	return ProductOptionTranslationRequestHygienised{
		title:         p.title
		locale_id:     p.locale_id
		locale_id_bin: locale_id_bin
	}
}

pub struct ProductOptionCreateRequest {
pub:
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

pub struct ProductOptionUpdateRequest {
pub:
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

pub struct ProductVariantMoneyAmountRequest {
pub:
	amount      i32
	region_id   string @[json: 'regionId']
	is_original ?bool  @[json: 'isOriginal']
}

struct ProductVariantMoneyAmountRequestHygienised {
	amount        i32
	region_id     string
	region_id_bin []u8
	is_original   ?bool
}

fn (p ProductVariantMoneyAmountRequest) hygienise() !ProductVariantMoneyAmountRequestHygienised {
	region_id_bin := option_id_string_to_id_bin(p.region_id) or {
		return new_internal_error(error_id_invalid, 'region_id')
	}

	return ProductVariantMoneyAmountRequestHygienised{
		amount:        p.amount
		region_id:     p.region_id
		region_id_bin: region_id_bin
	}
}

// used during product and product_variant creation
pub struct InventoryLevelCreateRequest {
pub:
	stock_location_id string @[json: 'stockLocationId']
	stocked_quantity  i32    @[json: 'stockedQuantity']
}

struct InventoryLevelCreateRequestHygienised {
	stock_location_id     string
	stock_location_id_bin []u8
	stocked_quantity      i32 @[json: 'stockedQuantity']
}

fn (p InventoryLevelCreateRequest) hygienise() !InventoryLevelCreateRequestHygienised {
	stock_location_id_bin := id_string_to_bin(p.stock_location_id)!
	return InventoryLevelCreateRequestHygienised{
		stock_location_id:     p.stock_location_id
		stock_location_id_bin: stock_location_id_bin
		stocked_quantity:      p.stocked_quantity
	}
}

pub struct InventoryLevelUpdateRequest {
pub:
	stocked_quantity i32 @[json: 'stockedQuantity']
}

// used during product and product_variant creation
pub struct InventoryItemCreateRequest {
pub:
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
	inventory_levels  ?[]InventoryLevelCreateRequest @[json: 'inventoryLevels']
}

struct InventoryItemCreateRequestHygienised {
	sku               ?string
	origin_country    ?string
	hs_code           ?string
	mid_code          ?string
	material          ?string
	weight            ?i32
	length            ?i32
	height            ?i32
	width             ?i32
	requires_shipping ?bool
	manage_inventory  ?bool
	allow_backorder   ?bool
mut:
	inventory_levels ?[]InventoryLevelCreateRequestHygienised
}

fn (p InventoryItemCreateRequest) hygienise() !InventoryItemCreateRequestHygienised {
	mut inventory_item := InventoryItemCreateRequestHygienised{
		sku:               p.sku
		origin_country:    p.origin_country
		hs_code:           p.hs_code
		mid_code:          p.mid_code
		material:          p.material
		weight:            p.weight
		length:            p.length
		height:            p.height
		width:             p.width
		requires_shipping: p.requires_shipping
		manage_inventory:  p.manage_inventory
		allow_backorder:   p.allow_backorder
	}

	if inventory_levels := p.inventory_levels {
		mut iih := []InventoryLevelCreateRequestHygienised{len: inventory_levels.len}
		for i := 0; i < inventory_levels.len; i++ {
			iih[i] = inventory_levels[i].hygienise()!
		}
		inventory_item.inventory_levels = iih
	}

	return inventory_item
}

pub struct InventoryItemUpdateRequest {
pub:
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

pub struct VariantCreateRequest {
pub:
	title            ?string
	ean              ?string
	upc              ?string
	barcode          ?string
	variant_rank     ?i32                               @[json: 'variantRank']
	inventory_item   ?InventoryItemCreateRequest        @[json: 'inventoryItem']
	option_value_ids ?[]string                          @[json: 'optionValueIds']
	metadata         ?string                            @[raw]
	money_amounts    []ProductVariantMoneyAmountRequest @[json: 'moneyAmounts']
}

struct ProductVariantCreateRequestHygienised {
	title                ?string
	ean                  ?string
	upc                  ?string
	barcode              ?string
	variant_rank         ?i32
	option_value_ids     ?[]string
	option_value_ids_bin [][]u8
	metadata             ?string
	money_amounts        []ProductVariantMoneyAmountRequestHygienised
mut:
	inventory_item ?InventoryItemCreateRequestHygienised
}

fn (p VariantCreateRequest) hygienise() !ProductVariantCreateRequestHygienised {
	option_value_ids_bin := option_array_id_string_to_array_id_bin(p.option_value_ids) or {
		return new_internal_error(error_id_invalid, 'ids_bin')
	}

	mut money_amounts := []ProductVariantMoneyAmountRequestHygienised{len: p.money_amounts.len}
	for i := 0; i < p.money_amounts.len; i++ {
		money_amounts[i] = p.money_amounts[i].hygienise()!
	}

	mut ph := ProductVariantCreateRequestHygienised{
		title:                p.title
		ean:                  p.ean
		upc:                  p.upc
		barcode:              p.barcode
		variant_rank:         p.variant_rank
		option_value_ids:     p.option_value_ids
		option_value_ids_bin: option_value_ids_bin
		metadata:             p.metadata
		money_amounts:        money_amounts
	}

	if inventory_item := p.inventory_item {
		ph.inventory_item = inventory_item.hygienise()!
	}

	return ph
}

pub struct VariantUpdateRequest {
pub:
	title            ?string
	ean              ?string
	upc              ?string
	barcode          ?string
	variant_rank     ?i32                                @[json: 'variantRank']
	inventory_item   ?InventoryItemUpdateRequest         @[json: 'inventoryItem']
	option_value_ids ?[]string                           @[json: 'optionValueIds']
	metadata         ?string                             @[raw]
	money_amounts    ?[]ProductVariantMoneyAmountRequest @[json: 'moneyAmounts']
}

struct ProductVariantUpdateRequestHygienised {
	title                ?string
	ean                  ?string
	upc                  ?string
	barcode              ?string
	variant_rank         ?i32
	inventory_item       ?InventoryItemUpdateRequest
	option_value_ids     ?[]string
	option_value_ids_bin [][]u8
	metadata             ?string
mut:
	money_amounts ?[]ProductVariantMoneyAmountRequestHygienised
}

fn (p VariantUpdateRequest) hygienise() !ProductVariantUpdateRequestHygienised {
	option_value_ids_bin := option_array_id_string_to_array_id_bin(p.option_value_ids) or {
		return new_internal_error(error_id_invalid, 'ids_bin')
	}

	mut ph := ProductVariantUpdateRequestHygienised{
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
		mut h := []ProductVariantMoneyAmountRequestHygienised{len: money_amounts.len}
		for i := 0; i < money_amounts.len; i++ {
			h[i] = money_amounts[i].hygienise()!
		}
		ph.money_amounts = h
	}

	return ph
}

// By default, taxes are automatically calculated by peony during checkout. This behavior can be disabled
// for a region to limit the requests being sent to a tax provider.
pub struct RegionCreateRequest {
pub:
	automatic_taxes ?bool    @[json: 'automaticTaxes']
	country_codes   []string @[json: 'countryCodes']
	currency_code   string   @[json: 'currencyCode']
	includes_tax    ?bool    @[json: 'includesTax']
	name            string
	// taxes
}

pub struct RegionUpdateRequest {
pub:
	automatic_taxes ?bool     @[json: 'automaticTaxes']
	country_codes   ?[]string @[json: 'countryCodes']
	currency_code   ?string   @[json: 'currencyCode']
	includes_tax    ?bool     @[json: 'includesTax']
	name            ?string
	//  taxes
}

pub struct CategoryTranslationRequest {
pub:
	locale_id   string @[json: 'localeId']
	name        ?string
	description ?string
}

struct CategoryTranslationRequestHygienised {
	locale_id     string
	locale_id_bin []u8
	name          ?string
	description   ?string
}

pub struct SEOTranslationUpdateRequest {
pub:
	locale_id   string @[json: 'localeId']
	title       ?string
	description ?string
}

struct SEOTranslationUpdateRequestHygienised {
	locale_id     string
	locale_id_bin []u8
	title         ?string
	description   ?string
}

fn (p SEOTranslationUpdateRequest) hygienise() !SEOTranslationUpdateRequestHygienised {
	locale_id_bin := id_string_to_bin(p.locale_id) or {
		return new_internal_error(error_id_invalid, 'locale_id')
	}

	return SEOTranslationUpdateRequestHygienised{
		locale_id:     p.locale_id
		locale_id_bin: locale_id_bin
		title:         p.title
		description:   p.description
	}
}

pub struct CategoryCreateRequest {
pub:
	handle             ?string
	is_internal        ?bool   @[json: 'isInternal']
	is_active          ?bool   @[json: 'isActive']
	parent_category_id ?string @[json: 'parentCategoryId']
	category_rank      ?i32    @[json: 'categoryRank']
	metadata           ?string @[raw]
	translations       []CategoryTranslationRequest
	seo_translations   ?[]SEOTranslationUpdateRequest @[json: 'seoTranslations']
}

struct CategoryCreateRequestHygienised {
	handle                 ?string
	is_internal            ?bool
	is_active              ?bool
	parent_category_id     ?string
	parent_category_id_bin []u8
	category_rank          ?i32
	metadata               ?string
	translations           []CategoryTranslationRequestHygienised
mut:
	seo_translations ?[]SEOTranslationUpdateRequestHygienised
}

fn (p CategoryCreateRequest) hygienise() !CategoryCreateRequestHygienised {
	mut parent_category_id_bin := []u8{}
	if parent_category_id := p.parent_category_id {
		parent_category_id_bin = id_string_to_bin(parent_category_id) or {
			return new_internal_error(error_id_invalid, 'parent_category_id')
		}
	}

	if p.translations.len == 0 {
		return new_internal_error(error_missing_default_translation, 'Provide at least one translation')
	}

	mut translations := []CategoryTranslationRequestHygienised{len: p.translations.len}
	for i := 0; i < p.translations.len; i++ {
		translation := p.translations[i]
		locale_id_bin := id_string_to_bin(translation.locale_id) or {
			return new_internal_error(error_id_invalid, 'locale_id')
		}
		translations[i] = CategoryTranslationRequestHygienised{
			locale_id:     translation.locale_id
			locale_id_bin: locale_id_bin
			name:          translation.name
			description:   translation.description
		}
	}

	mut ph := CategoryCreateRequestHygienised{
		handle:                 p.handle
		is_internal:            p.is_internal
		is_active:              p.is_active
		parent_category_id:     p.parent_category_id
		parent_category_id_bin: parent_category_id_bin
		category_rank:          p.category_rank
		metadata:               p.metadata
		translations:           translations
	}

	if seo_translations := p.seo_translations {
		mut st := []SEOTranslationUpdateRequestHygienised{len: seo_translations.len}
		for i := 0; i < seo_translations.len; i++ {
			translation := seo_translations[i]
			locale_id_bin := id_string_to_bin(translation.locale_id) or {
				return new_internal_error(error_id_invalid, 'locale_id')
			}
			st[i] = SEOTranslationUpdateRequestHygienised{
				locale_id:     translation.locale_id
				locale_id_bin: locale_id_bin
				title:         translation.title
				description:   translation.description
			}
		}
		ph.seo_translations = st
	}

	return ph
}

pub struct CategoryUpdateRequest {
pub:
	handle             ?string
	is_internal        ?bool   @[json: 'isInternal']
	is_active          ?bool   @[json: 'isActive']
	parent_category_id ?string @[json: 'parentCategoryId']
	category_rank      ?i32    @[json: 'categoryRank']
	metadata           ?string @[raw]
	translations       ?[]CategoryTranslationRequest
	seo_translations   ?[]SEOTranslationUpdateRequest @[json: 'seoTranslations']
}

struct CategoryUpdateRequestHygienised {
	handle                 ?string
	is_internal            ?bool
	is_active              ?bool
	parent_category_id     ?string
	parent_category_id_bin []u8
	category_rank          ?i32
	metadata               ?string
mut:
	translations     ?[]CategoryTranslationRequestHygienised
	seo_translations ?[]SEOTranslationUpdateRequestHygienised
}

fn (p CategoryUpdateRequest) hygienise() !CategoryUpdateRequestHygienised {
	if p.handle == none && p.is_internal == none && p.is_active == none
		&& p.parent_category_id == none && p.metadata == none && p.translations == none
		&& p.seo_translations == none {
		return new_internal_error(error_empty_object, 'CategoryUpdateRequest')
	}

	mut parent_category_id_bin := []u8{}
	if parent_category_id := p.parent_category_id {
		parent_category_id_bin = id_string_to_bin(parent_category_id) or {
			return new_internal_error(error_id_invalid, 'parent_category_id')
		}
	}

	mut ph := CategoryUpdateRequestHygienised{
		handle:                 p.handle
		is_internal:            p.is_internal
		is_active:              p.is_active
		parent_category_id:     p.parent_category_id
		parent_category_id_bin: parent_category_id_bin
		category_rank:          p.category_rank
		metadata:               p.metadata
	}

	if seo_translations := p.seo_translations {
		if seo_translations.len == 0 {
			return new_internal_error(error_empty_object, 'seo_translations')
		}

		mut st := []SEOTranslationUpdateRequestHygienised{len: seo_translations.len}
		for i := 0; i < seo_translations.len; i++ {
			translation := seo_translations[i]
			locale_id_bin := id_string_to_bin(translation.locale_id) or {
				return new_internal_error(error_id_invalid, 'locale_id')
			}
			st[i] = SEOTranslationUpdateRequestHygienised{
				locale_id:     translation.locale_id
				locale_id_bin: locale_id_bin
				title:         translation.title
				description:   translation.description
			}
		}
		ph.seo_translations = st
	}

	if translations := p.translations {
		if translations.len == 0 {
			return new_internal_error(error_empty_object, 'translations')
		}

		mut t := []CategoryTranslationRequestHygienised{len: translations.len}
		for i := 0; i < translations.len; i++ {
			translation := translations[i]
			locale_id_bin := id_string_to_bin(translation.locale_id) or {
				return new_internal_error(error_id_invalid, 'locale_id')
			}
			t[i] = CategoryTranslationRequestHygienised{
				locale_id:     translation.locale_id
				locale_id_bin: locale_id_bin
				name:          translation.name
				description:   translation.description
			}
		}
		ph.translations = t
	}

	return ph
}

// The `thumbnail` field must always be the index of one image in the `images` array.
// If `thumbnail` is not provided, peony selects the first image in `images` as the thumbnail.
// If `images` is empty or omitted, the product is created without a thumbnail or images.
pub struct ProductCreateRequest {
pub:
	handle            ?string
	is_giftcard       ?bool @[json: 'isGiftcard']
	status            ?string
	type_id           ?string @[json: 'typeId']
	discountable      ?bool
	metadata          ?string   @[raw]
	tag_ids           ?[]string @[json: 'tagIds']
	sales_channel_ids ?[]string @[json: 'salesChannelIds']
	category_ids      ?[]string @[json: 'categoryIds']
	collection_ids    ?[]string @[json: 'collectionIds']
	translations      ?[]ProductTranslationRequest
	seo_translations  ?[]SEOTranslationUpdateRequest @[json: 'seoTranslations']
	options           ?[]ProductOptionCreateRequest
	thumbnail         ?i32
	images            ?[]ImageRequest
}

struct ProductCreateRequestHygienised {
	handle                ?string
	is_giftcard           ?bool
	status                ?string
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
	thumbnail             ?i32
mut:
	options          ?[]ProductOptionCreateRequestHygienised
	translations     ?[]ProductTranslationRequestHygienised
	seo_translations ?[]SEOTranslationUpdateRequestHygienised
	images           ?[]ImageRequestHygienised
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

	if seo_translations := p.seo_translations {
		mut st := []SEOTranslationUpdateRequestHygienised{len: seo_translations.len}
		for i := 0; i < st.len; i++ {
			st[i] = seo_translations[i].hygienise()!
		}
		ph.seo_translations = st
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

// If `thumbnail` is provided and `images` is empty, the image whose `rank` equals `thumbnail` is used
// as the product thumbnail.
// If both `thumbnail` and `images` are provided, the thumbnail is the image at index `thumbnail` in
// the `images` array.
struct ProductUpdateRequest {
	handle            ?string
	is_giftcard       ?bool @[json: 'isGiftcard']
	status            ?string
	type_id           ?string @[json: 'typeId']
	discountable      ?bool
	metadata          ?string   @[raw]
	tag_ids           ?[]string @[json: 'tagIds']
	sales_channel_ids ?[]string @[json: 'salesChannelIds']
	category_ids      ?[]string @[json: 'categoryIds']
	collection_ids    ?[]string @[json: 'collectionIds']
	translations      ?[]ProductTranslationRequest
	seo_translations  ?[]SEOTranslationUpdateRequest
	thumbnail         ?i32
	images            ?[]ImageRequest
}

struct ProductUpdateRequestHygienised {
	handle                ?string
	is_giftcard           ?bool
	status                ?string
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
	thumbnail             ?i32
mut:
	translations     ?[]ProductTranslationRequestHygienised
	seo_translations ?[]SEOTranslationUpdateRequestHygienised
	images           ?[]ImageRequestHygienised
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
		thumbnail:             p.thumbnail
	}

	if translations := p.translations {
		mut h := []ProductTranslationRequestHygienised{len: translations.len}
		for i := 0; i < translations.len; i++ {
			h[i] = hygienise_product_translation_request(translations[i])!
		}
		ph.translations = h
	}

	if seo_translations := p.seo_translations {
		mut st := []SEOTranslationUpdateRequestHygienised{len: seo_translations.len}
		for i := 0; i < st.len; i++ {
			st[i] = seo_translations[i].hygienise()!
		}
		ph.seo_translations = st
	}

	if images := p.images {
		mut h := []ImageRequestHygienised{len: images.len}
		for i := 0; i < images.len; i++ {
			h[i] = images[i].hygienise()!
		}
		ph.images = h
	}

	// thumbnail:             p.thumbnail

	return ph
}
