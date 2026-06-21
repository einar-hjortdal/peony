module peony

import arrays
import json
import internal.conduit
import internal.errors

pub const category_default_is_active = true
pub const category_default_is_internal = false

pub const region_default_automatic_taxes = true
pub const region_default_includes_tax = false
pub const region_default_gift_cards_taxable = true
pub const sales_channel_default_is_disabled = false

pub const max_length_region_name = 63
pub const country_code_length = 2 // ISO 3166-1 alpha 2
pub const currency_code_length = 3 // ISO 4217
pub const max_length_sales_channel_name = 63
pub const max_length_sales_channel_description = 191

pub struct AuthRequest {
pub:
	email    string
	password string
}

pub struct APIKeyCreateRequest {
pub:
	name             string
	sales_channel_id string
}

fn hygienise_api_key_create_request(s string, api_key_id ID) !conduit.APIKeyCreateParams {
	p := json.decode(APIKeyCreateRequest, s) or {
		return errors.bad_request('Could not decode APIKeyCreateRequest', err.msg())
	}

	if utf8_str_visible_length(p.name) > max_length_api_key_name {
		return errors.bad_request(error_field_too_long,
			'name can be at most ${max_length_api_key_name} UTF8 characters long')
	}

	sales_channel_id := id_from_string(p.sales_channel_id) or {
		return errors.unprocessable_entity(error_id_invalid, 'sales_channel_id')
	}

	return conduit.APIKeyCreateParams{
		id:               api_key_id
		name:             p.name
		sales_channel_id: sales_channel_id
	}
}

pub struct APIKeyUpdateRequest {
pub:
	name             ?string
	sales_channel_id ?string
}

fn hygienise_api_key_update_request(s string, api_key_id ID) !conduit.APIKeyUpdateParams {
	p := json.decode(APIKeyUpdateRequest, s) or {
		return errors.bad_request('Could not decode APIKeyUpdateRequest', err.msg())
	}

	if p.name == none && p.sales_channel_id == none {
		return errors.bad_request(error_empty_object, 'APIKeyUpdateRequest')
	}

	if name := p.name {
		if utf8_str_visible_length(name) > max_length_api_key_name {
			return errors.bad_request(error_field_too_long,
				'name can be at most ${max_length_api_key_name} UTF8 characters long')
		}
	}

	mut sales_channel_id := ?ID(none)
	if id_string := p.sales_channel_id {
		sales_channel_id = id_from_string(id_string) or {
			return errors.unprocessable_entity(error_id_invalid, 'sales_channel_id')
		}
	}

	return conduit.APIKeyUpdateParams{
		id:               api_key_id
		name:             p.name
		sales_channel_id: sales_channel_id
	}
}

pub struct StoreUpdateRequest {
pub:
	name                      ?string
	default_locale_id         ?string   @[json: 'defaultLocaleId']
	default_region_id         ?string   @[json: 'defaultRegionId']
	default_stock_location_id ?string   @[json: 'defaultStockLocationId']
	default_sales_channel_id  ?string   @[json: 'defaultSalesChannelId']
	locale_ids                ?[]string @[json: 'localeIds']
}

fn hygienise_store_request(s string, store_id ID) !conduit.StoreUpdateParams {
	p := json.decode(StoreUpdateRequest, s) or {
		return errors.bad_request('Could not decode StoreUpdateRequest', err.msg())
	}

	mut parsed_default_locale_id := ?ID(none)
	if id := p.default_locale_id {
		parsed_default_locale_id = id_from_string(id) or {
			return errors.bad_request(error_id_invalid, 'default_locale_id')
		}
	}

	mut parsed_default_region_id := ?ID(none)
	if id := p.default_region_id {
		parsed_default_region_id = id_from_string(id) or {
			return errors.bad_request(error_id_invalid, 'default_region_id')
		}
	}

	mut parsed_default_stock_location_id := ?ID(none)
	if id := p.default_stock_location_id {
		parsed_default_stock_location_id = id_from_string(id) or {
			return errors.bad_request(error_id_invalid, 'default_stock_location_id')
		}
	}

	mut parsed_default_sales_channel_id := ?ID(none)
	if id := p.default_sales_channel_id {
		parsed_default_sales_channel_id = id_from_string(id) or {
			return errors.bad_request(error_id_invalid, 'default_sales_channel_id')
		}
	}

	mut parsed_locale_ids := ?[]ID(none)
	if ids := p.locale_ids {
		parsed_locale_ids = ids_from_array_string(ids) or {
			return errors.unprocessable_entity(error_id_invalid, 'locale_ids')
		}
	}

	return conduit.StoreUpdateParams{
		id:                        store_id
		name:                      p.name
		default_locale_id:         parsed_default_locale_id
		default_region_id:         parsed_default_region_id
		default_stock_location_id: parsed_default_stock_location_id
		default_sales_channel_id:  parsed_default_sales_channel_id
		locale_ids:                parsed_locale_ids
	}
}

pub struct SalesChannelCreateRequest {
pub:
	name        string
	description ?string
	is_disabled ?bool @[json: 'isDisabled']
}

fn hygienise_sales_channel_create_request(s string, sales_channel_id ID) !conduit.SalesChannelCreateParams {
	p := json.decode(SalesChannelCreateRequest, s) or {
		return errors.bad_request('Could not decode SalesChannelCreateRequest', err.msg())
	}

	if p.name == '' {
		return errors.unprocessable_entity(error_field_empty, 'name')
	}

	if utf8_str_visible_length(p.name) > max_length_sales_channel_name {
		return errors.unprocessable_entity(error_field_too_long,
			'name can be at most ${max_length_sales_channel_name} UTF8 characters long')
	}

	if description := p.description {
		if utf8_str_visible_length(description) > max_length_sales_channel_description {
			return errors.unprocessable_entity(error_field_too_long,
				'description can be at most ${max_length_sales_channel_description} UTF8 characters long')
		}
	}

	return conduit.SalesChannelCreateParams{
		id:          sales_channel_id
		name:        p.name
		description: p.description
		is_disabled: bool_or(p.is_disabled, sales_channel_default_is_disabled)
	}
}

pub struct SalesChannelUpdateRequest {
pub:
	name        ?string
	description ?string
	is_disabled ?bool @[json: 'isDisabled']
}

fn hygienise_sales_channel_update_request(s string, sales_channel_id ID) !conduit.SalesChannelUpdateParams {
	p := json.decode(SalesChannelUpdateRequest, s) or {
		return errors.bad_request('Could not decode SalesChannelUpdateRequest', err.msg())
	}

	if name := p.name {
		if name == '' {
			return errors.unprocessable_entity(error_field_empty, 'name')
		}

		if utf8_str_visible_length(p.name) > max_length_sales_channel_name {
			return errors.unprocessable_entity(error_field_too_long,
				'name can be at most ${max_length_sales_channel_name} UTF8 characters long')
		}
	}

	if description := p.description {
		if utf8_str_visible_length(description) > max_length_sales_channel_description {
			return errors.unprocessable_entity(error_field_too_long,
				'description can be at most ${max_length_sales_channel_description} UTF8 characters long')
		}
	}

	return conduit.SalesChannelUpdateParams{
		id:          sales_channel_id
		name:        p.name
		description: p.description
		is_disabled: p.is_disabled
	}
}

pub struct ImageTranslationRequest {
pub:
	alt string
}

struct ImageTranslationRequestHygienised {
	locale_id ID
	alt       string
}

fn hygienise_image_translations(p map[string]ImageTranslationRequest) ![]ImageTranslationRequestHygienised {
	mut res := []ImageTranslationRequestHygienised{len: p.len}
	mut i := 0
	for locale_id, translation in p {
		parsed_locale_id := id_from_string(locale_id) or {
			return errors.unprocessable_entity(error_id_invalid, 'locale_id')
		}

		res[i] = ImageTranslationRequestHygienised{
			locale_id: parsed_locale_id
			alt:       translation.alt
		}
		i++
	}
	return res
}

// ImageCreateRequest describes the body of the request to create a new product image.
//
// # Fields
//
// ## url
// Image source URL. This field is required.
//
// ## alt
// Alternative text for the image. If omitted, no alt text is set.
//
// ## translations
// Localized versions of image fields. The keys of the map are the locale id.
pub struct ImageCreateRequest {
pub:
	url          string
	alt          ?string
	translations ?map[string]ImageTranslationRequest
}

struct ImageCreateRequestHygienised {
	url string
	alt ?string
mut:
	translations ?[]ImageTranslationRequestHygienised
}

fn (p ImageCreateRequest) hygienise() !ImageCreateRequestHygienised {
	if alt := p.alt {
		if utf8_str_visible_length(alt) > max_length_alt {
			return errors.bad_request(error_field_too_long,
				'alt can be at most ${max_length_alt} UTF8 characters long')
		}
	}

	mut image := ImageCreateRequestHygienised{
		url: p.url
		alt: p.alt
	}

	if translations := p.translations {
		image.translations = hygienise_image_translations(translations)!
	}
	return image
}

// ImageUpdateRequest describes the body of the request to create or update a product image.
//
// # Fields
//
// ## id
// Image identifier. If provided, the existing image with this id is updated.
//
// ## url
// Image source URL. Only allowed when creating a new image.
// If `id` is provided, this field must not be set.
//
// ## alt
// Alternative text for the image. If omitted during update, the existing alt text is preserved.
//
// ## translations
// Localized versions of image fields. The keys of the map are the locale id.
// To remove all translations, submit an empty map.
pub struct ImageUpdateRequest {
pub:
	id           ?string
	url          ?string
	alt          ?string
	translations ?map[string]ImageTranslationRequest
}

struct ImageUpdateRequestHygienised {
	id  ?ID
	url ?string
	alt ?string
mut:
	translations ?[]ImageTranslationRequestHygienised
}

fn (p ImageUpdateRequest) hygienise() !ImageUpdateRequestHygienised {
	if p.id != none && p.url != none {
		return errors.unprocessable_entity('unable to update image url', 'both id and url are set')
	}

	if p.id == none && p.url == none {
		return errors.unprocessable_entity('unable to create image without url',
			'both id and url are unset')
	}

	if alt := p.alt {
		if utf8_str_visible_length(alt) > max_length_alt {
			return errors.unprocessable_entity(error_field_too_long,
				'alt can be at most ${max_length_alt} UTF8 characters long')
		}
	}

	mut parsed_id := ?ID(none)
	if id := p.id {
		parsed_id = id_from_string(id) or {
			return errors.unprocessable_entity(error_id_invalid, 'id')
		}
	}

	mut image := ImageUpdateRequestHygienised{
		id:  parsed_id
		url: p.url
		alt: p.alt
	}

	if translations := p.translations {
		image.translations = hygienise_image_translations(translations)!
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
	image      ?ImageCreateRequest
	metadata   ?string @[raw]
}

fn (p UserCreateRequest) hygienise() ! {
	email_is_valid(p.email) or { return errors.bad_request('invalid email', err.msg()) }

	if p.password == '' {
		return errors.bad_request(error_field_empty, 'password')
	}

	if role := p.role {
		role_is_valid(role)!
	}

	if first_name := p.first_name {
		if utf8_str_visible_length(first_name) > max_length_first_name {
			return errors.bad_request('first_name too long',
				'first_name can be at most ${max_length_first_name} UTF8 characters long')
		}
	}

	if last_name := p.last_name {
		if utf8_str_visible_length(last_name) > max_length_last_name {
			return errors.bad_request('last_name too long',
				'last_name can be at most ${max_length_last_name} UTF8 characters long')
		}
	}

	if image := p.image {
		if alt := image.alt {
			if utf8_str_visible_length(alt) > max_length_alt {
				return errors.bad_request('alt too long',
					'alt can be at most ${max_length_alt} UTF8 characters long')
			}
		}
	}
}

pub struct UserUpdateRequest {
pub:
	email      ?string
	first_name ?string @[json: 'firstName']
	last_name  ?string @[json: 'lastName']
	role       ?string
	image      ?ImageUpdateRequest
	metadata   ?string @[raw]
}

fn (p UserUpdateRequest) hygienise() ! {
	if email := p.email {
		email_is_valid(email) or { return errors.bad_request('invalid email', err.msg()) }
	}

	if role := p.role {
		role_is_valid(role)!
	}

	if first_name := p.first_name {
		if utf8_str_visible_length(first_name) > max_length_first_name {
			return errors.bad_request('first_name too long',
				'first_name can be at most ${max_length_first_name} UTF8 characters long')
		}
	}

	if last_name := p.last_name {
		if utf8_str_visible_length(last_name) > max_length_last_name {
			return errors.bad_request('last_name too long',
				'last_name can be at most ${max_length_last_name} UTF8 characters long')
		}
	}

	if image := p.image {
		if alt := image.alt {
			if utf8_str_visible_length(alt) > max_length_alt {
				return errors.bad_request('alt too long',
					'alt can be at most ${max_length_alt} UTF8 characters long')
			}
		}
	}
}

pub struct ProductTranslationRequest {
pub:
	title       ?string
	subtitle    ?string
	description ?string
}

struct ProductTranslationRequestHygienised {
	locale_id   ID
	title       ?string
	subtitle    ?string
	description ?string
}

fn hygienise_product_translations(p map[string]ProductTranslationRequest) ![]ProductTranslationRequestHygienised {
	mut res := []ProductTranslationRequestHygienised{len: p.len}
	mut i := 0
	for locale_id, translation in p {
		parsed_locale_id := id_from_string(locale_id) or {
			return errors.unprocessable_entity(error_id_invalid, 'locale_id')
		}

		res[i] = ProductTranslationRequestHygienised{
			locale_id:   parsed_locale_id
			title:       translation.title
			subtitle:    translation.subtitle
			description: translation.description
		}
		i++
	}
	return res
}

pub struct ProductOptionValueTranslationRequest {
pub:
	name string
}

struct ProductOptionValueTranslationRequestHygienised {
	locale_id ID
	name      string
}

fn hygienise_product_option_value_translations(p map[string]ProductOptionValueTranslationRequest) ![]ProductOptionValueTranslationRequestHygienised {
	mut res := []ProductOptionValueTranslationRequestHygienised{len: p.len}
	mut i := 0
	for locale_id, translation in p {
		parsed_locale_id := id_from_string(locale_id) or {
			return errors.unprocessable_entity(error_id_invalid, 'locale_id')
		}

		res[i] = ProductOptionValueTranslationRequestHygienised{
			locale_id: parsed_locale_id
			name:      translation.name
		}
		i++
	}
	return res
}

pub struct ProductOptionValueRequest {
pub:
	name         string
	translations ?map[string]ProductOptionValueTranslationRequest
}

struct ProductOptionValueRequestHygienised {
	name string
mut:
	translations ?[]ProductOptionValueTranslationRequestHygienised
}

fn (p ProductOptionValueRequest) hygienise() !ProductOptionValueRequestHygienised {
	if p.name == '' {
		return errors.bad_request(error_field_empty, 'product_option_value name is required')
	}

	mut ph := ProductOptionValueRequestHygienised{
		name: p.name
	}

	if translations := p.translations {
		ph.translations = hygienise_product_option_value_translations(translations)!
	}

	return ph
}

// ProductOptionValueUpdateRequest describes an option value object used in option update requests.
//
// Fields
//
// id
// Optional identifier of the option value.
// If provided, the request updates the existing value with this id.
// If omitted, a new value will be created.
//
// name
// Option value name (for example "Red" or "Large").
// Required when creating a new value (that is, when id is omitted).
// If omitted when id is present, the value name is not changed.
// If an empty string is provided, the value name is set to an empty string.
//
// translations
// When provided, `translations` replaces the option value's existing translations.
// To remove all existing translations, submit an empty array.
// If omitted, translations are left unchanged.
pub struct ProductOptionValueUpdateRequest {
pub:
	id           ?string
	name         ?string
	translations ?map[string]ProductOptionValueTranslationRequest
}

struct ProductOptionValueUpdateRequestHygienised {
	id   ?ID
	name ?string
mut:
	translations ?[]ProductOptionValueTranslationRequestHygienised
}

fn (p ProductOptionValueUpdateRequest) hygienise() !ProductOptionValueUpdateRequestHygienised {
	if p.name == none && p.translations == none {
		return errors.bad_request(error_empty_object, 'ProductOptionValueUpdateRequest')
	}

	mut parsed_id := ?ID(none)
	if id := p.id {
		parsed_id = id_from_string(id) or {
			return errors.unprocessable_entity(error_id_invalid, 'id')
		}
	}

	mut ph := ProductOptionValueUpdateRequestHygienised{
		id:   parsed_id
		name: p.name
	}

	if translations := p.translations {
		ph.translations = hygienise_product_option_value_translations(translations)!
	}

	return ph
}

pub struct ProductOptionTranslationRequest {
pub:
	title string
}

struct ProductOptionTranslationRequestHygienised {
	title     string
	locale_id ID
}

fn hygienise_product_option_translations(p map[string]ProductOptionTranslationRequest) ![]ProductOptionTranslationRequestHygienised {
	mut res := []ProductOptionTranslationRequestHygienised{len: p.len}
	mut i := 0
	for locale_id, translation in p {
		parsed_locale_id := id_from_string(locale_id) or {
			return errors.unprocessable_entity(error_id_invalid, 'locale_id')
		}

		res[i] = ProductOptionTranslationRequestHygienised{
			locale_id: parsed_locale_id
			title:     translation.title
		}
		i++
	}
	return res
}

pub struct ProductOptionCreateRequest {
pub:
	title        string
	translations ?map[string]ProductOptionTranslationRequest
	values       []ProductOptionValueRequest
}

struct ProductOptionCreateRequestHygienised {
	title  string
	values []ProductOptionValueRequestHygienised
mut:
	translations ?[]ProductOptionTranslationRequestHygienised
}

fn (p ProductOptionCreateRequest) hygienise() !ProductOptionCreateRequestHygienised {
	if p.title == '' {
		return errors.bad_request(error_field_empty, 'product_option title is required')
	}

	if p.values.len == 0 {
		return errors.bad_request(error_field_empty,
			'The product_option lacks values, at least one value must be provided.')
	}

	mut values := []ProductOptionValueRequestHygienised{len: p.values.len}
	for i := 0; i < p.values.len; i++ {
		values[i] = p.values[i].hygienise()!
	}

	mut ph := ProductOptionCreateRequestHygienised{
		title:  p.title
		values: values
	}

	if translations := p.translations {
		ph.translations = hygienise_product_option_translations(translations)!
	}

	return ph
}

// ProductOptionUpdateRequest describes a product option object used in product update requests.
//
// # Fields
//
// ## id
// Optional identifier of the product option.
// If provided, the request updates the existing option with this id.
// If omitted, a new option will be created in the product's options array.
//
// ## title
// Option title.
// Required if id is omitted.
// If omitted, the option's title is not changed.
//
// ## translations
// Localized versions of product option fields. The keys of the map are the locale id.
// To remove all translations, submit an empty object.
//
// values
// When provided, `values` is a replacement array for the option's values.
// - Items with `id` update that value, items without `id` are created.
// - Omitted existing values are removed.
// - The array index is preserved.
// - The index in the values array is the valueRank for that option.
pub struct ProductOptionUpdateRequest {
pub:
	id           ?string
	title        ?string
	translations ?map[string]ProductOptionTranslationRequest
	values       ?[]ProductOptionValueUpdateRequest
}

struct ProductOptionUpdateRequestHygienised {
	id    ?ID
	title ?string
mut:
	translations ?[]ProductOptionTranslationRequestHygienised
	values       ?[]ProductOptionValueUpdateRequestHygienised
}

fn (p ProductOptionUpdateRequest) hygienise() !ProductOptionUpdateRequestHygienised {
	mut parsed_id := ?ID(none)
	if id := p.id {
		parsed_id = id_from_string(id) or {
			return errors.unprocessable_entity(error_id_invalid, 'id')
		}
	}

	mut ph := ProductOptionUpdateRequestHygienised{
		id:    parsed_id
		title: p.title
	}

	if translations := p.translations {
		ph.translations = hygienise_product_option_translations(translations)!
	}

	// TODO values are missing here

	return ph
}

pub struct VariantPriceRequest {
pub:
	original_price ?i32 @[json: 'originalPrice']
	base_price     i32  @[json: 'basePrice']
}

struct VariantMoneyAmountRequestHygienised {
	amount      i32
	region_id   ID
	is_original bool
}

fn get_money_amounts_from_regional_prices(p map[string]VariantPriceRequest) ![]VariantMoneyAmountRequestHygienised {
	mut money_amounts := []VariantMoneyAmountRequestHygienised{}
	region_ids := p.keys()
	for i := 0; i < region_ids.len; i++ {
		region_id := region_ids[i]
		parsed_region_id := id_from_string(region_id) or {
			return errors.unprocessable_entity(error_id_invalid, 'region_id')
		}

		price := p[region_id]

		base_price := price.base_price
		if base_price < 0 {
			return errors.unprocessable_entity('invalid money amount', 'A price cannot be negative')
		}

		money_amounts = arrays.concat(money_amounts, VariantMoneyAmountRequestHygienised{
			amount:      base_price
			region_id:   parsed_region_id
			is_original: false
		})

		if original_price := price.original_price {
			if original_price < 0 {
				return errors.unprocessable_entity('invalid money amount',
					'A price cannot be negative')
			}

			money_amounts = arrays.concat(money_amounts, VariantMoneyAmountRequestHygienised{
				amount:      original_price
				region_id:   parsed_region_id
				is_original: true
			})
		}
	}

	return money_amounts
}

// used during product and variant creation
pub struct InventoryLevelCreateRequest {
pub:
	stock_location_id string @[json: 'stockLocationId']
	stocked_quantity  i32    @[json: 'stockedQuantity']
}

struct InventoryLevelCreateRequestHygienised {
	stock_location_id ID
	stocked_quantity  i32 @[json: 'stockedQuantity']
}

fn (p InventoryLevelCreateRequest) hygienise() !InventoryLevelCreateRequestHygienised {
	parsed_stock_location_id := id_from_string(p.stock_location_id) or {
		return errors.unprocessable_entity(error_id_invalid, 'stock_location_id')
	}

	return InventoryLevelCreateRequestHygienised{
		stock_location_id: parsed_stock_location_id
		stocked_quantity:  p.stocked_quantity
	}
}

pub struct InventoryLevelUpdateRequest {
pub:
	stocked_quantity i32 @[json: 'stockedQuantity']
}

fn hygienise_inventory_level_update_request(s string, inventory_item_id ID, stock_location_id ID) !conduit.InventoryLevelUpdateParams {
	p := json.decode(InventoryLevelUpdateRequest, s) or {
		return errors.bad_request('Could not decode InventoryLevelUpdateRequest', err.msg())
	}

	return conduit.InventoryLevelUpdateParams{
		inventory_item_id: inventory_item_id
		stock_location_id: stock_location_id
		stocked_quantity:  p.stocked_quantity
	}
}

// used during product and variant creation
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
}

fn (p InventoryItemCreateRequest) hygienise() !InventoryItemCreateRequestHygienised {
	if sku := p.sku {
		if utf8_str_visible_length(sku) > max_length_sku {
			return errors.unprocessable_entity(error_field_too_long, 'sku')
		}
	}

	if origin_country := p.origin_country {
		if utf8_str_visible_length(origin_country) > max_length_country {
			return errors.unprocessable_entity(error_field_too_long, format_field_too_long_details('origin_country',
				max_length_country))
		}
	}

	if hs_code := p.hs_code {
		if utf8_str_visible_length(hs_code) > max_length_hs_code {
			return errors.unprocessable_entity(error_field_too_long, format_field_too_long_details('hs_code',
				max_length_hs_code))
		}
	}

	if mid_code := p.mid_code {
		if utf8_str_visible_length(mid_code) > max_length_mid_code {
			return errors.unprocessable_entity(error_field_too_long, format_field_too_long_details('mid_code',
				max_length_mid_code))
		}
	}

	if material := p.material {
		if utf8_str_visible_length(material) > max_length_material {
			return errors.unprocessable_entity(error_field_too_long, format_field_too_long_details('material',
				max_length_material))
		}
	}

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

	return inventory_item
}

fn (p InventoryItemCreateRequestHygienised) is_empty() bool {
	return p.sku == none && p.origin_country == none && p.hs_code == none && p.mid_code == none
		&& p.material == none && p.weight == none && p.length == none && p.height == none
		&& p.width == none && p.manage_inventory == none && p.requires_shipping == none
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

struct InventoryItemUpdateRequestHygienised {
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
}

fn (p InventoryItemUpdateRequest) hygienise() !InventoryItemUpdateRequestHygienised {
	if sku := p.sku {
		if utf8_str_visible_length(sku) > max_length_sku {
			return errors.unprocessable_entity(error_field_too_long, 'sku')
		}
	}

	if origin_country := p.origin_country {
		if utf8_str_visible_length(origin_country) > max_length_country {
			return errors.unprocessable_entity(error_field_too_long, format_field_too_long_details('origin_country',
				max_length_country))
		}
	}

	if hs_code := p.hs_code {
		if utf8_str_visible_length(hs_code) > max_length_hs_code {
			return errors.unprocessable_entity(error_field_too_long, format_field_too_long_details('hs_code',
				max_length_hs_code))
		}
	}

	if mid_code := p.mid_code {
		if utf8_str_visible_length(mid_code) > max_length_mid_code {
			return errors.unprocessable_entity(error_field_too_long, format_field_too_long_details('mid_code',
				max_length_mid_code))
		}
	}

	if material := p.material {
		if utf8_str_visible_length(material) > max_length_material {
			return errors.unprocessable_entity(error_field_too_long, format_field_too_long_details('material',
				max_length_material))
		}
	}

	mut inventory_item := InventoryItemUpdateRequestHygienised{
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

	return inventory_item
}

fn (p InventoryItemUpdateRequestHygienised) is_empty() bool {
	return p.sku == none && p.origin_country == none && p.hs_code == none && p.mid_code == none
		&& p.material == none && p.weight == none && p.length == none && p.height == none
		&& p.width == none && p.manage_inventory == none && p.requires_shipping == none
}

// ProductVariantCreateRequest describes the variant to create during product creation.
//
// # Fields
//
// ## title
// Variant title, typically a combination of option value names (e.g., "Large/Red").
//
// ## ean
// European Article Number (EAN) for the variant.
//
// ## upc
// Universal Product Code (UPC) for the variant.
//
// ## barcode
// Generic barcode field.
//
// ## image
// Index of the product image related to this variant.
//
// ## inventory_item
// See InventoryItemUpdateRequest.
//
// ## option_values
// Required if more than one variant is provided.
// If omitted, the variant to be created is the product's default variant.
// Array of integers that maps this variant to option values by option position.
// - The array must contain exactly one element per product option.
// - The element index represents the option index, while the element value represents the value index.
// For example, `option_value_indices: [2, 0, 1]` means: option at index `0` uses value index `2`; option at index `1` uses value index `0`; option at index `2` uses value index `1`.
//
// ## metadata
// Raw metadata stored as a string. Use for arbitrary user-defined data.
//
// ## prices
// Regional prices for the variant. The keys of the map are the region ids.
// If omitted, a base price of 0 will be created for each region.
// If provided:
// - For each region, there must be exactly one `base_price`.
// - For each region, there may be one `original price`.
pub struct ProductVariantCreateRequest {
pub:
	title           ?string
	ean             ?string
	upc             ?string
	barcode         ?string
	image           ?i32
	inventory_item  ?InventoryItemCreateRequest     @[json: 'inventoryItem']
	option_values   ?[]i32                          @[json: 'optionValues']
	metadata        ?string                         @[raw]
	regional_prices ?map[string]VariantPriceRequest @[json: 'regionalPrices']
}

struct ProductVariantCreateRequestHygienised {
	title         ?string
	ean           ?string
	upc           ?string
	barcode       ?string
	image         ?i32
	option_values ?[]i32
	metadata      ?string
mut:
	inventory_item ?InventoryItemCreateRequestHygienised
	money_amounts  ?[]VariantMoneyAmountRequestHygienised
}

fn (p ProductVariantCreateRequest) hygienise() !ProductVariantCreateRequestHygienised {
	if title := p.title {
		if utf8_str_visible_length(title) > max_length_variant_title {
			return errors.bad_request(error_field_too_long, format_field_too_long_details('title',
				max_length_variant_title))
		}
	}

	if ean := p.ean {
		if utf8_str_visible_length(ean) > max_length_ean {
			return errors.bad_request(error_field_too_long, format_field_too_long_details('ean',
				max_length_ean))
		}
	}

	if upc := p.upc {
		if utf8_str_visible_length(upc) > max_length_upc {
			return errors.bad_request(error_field_too_long, format_field_too_long_details('upc',
				max_length_upc))
		}
	}

	if barcode := p.barcode {
		if utf8_str_visible_length(barcode) > max_length_barcode {
			return errors.bad_request(error_field_too_long, format_field_too_long_details('barcode',
				max_length_barcode))
		}
	}

	// Reject creation of a variant with 0 option values
	if option_values := p.option_values {
		if option_values.len == 0 {
			return errors.unprocessable_entity(error_field_empty,
				'A variant must reference at least one option')
		}
	}

	mut ph := ProductVariantCreateRequestHygienised{
		title:         p.title
		ean:           p.ean
		upc:           p.upc
		barcode:       p.barcode
		image:         p.image
		option_values: p.option_values
		metadata:      p.metadata
	}

	if inventory_item := p.inventory_item {
		ph.inventory_item = inventory_item.hygienise()!
	}

	if prices := p.regional_prices {
		if prices.len == 0 {
			errors.bad_request(error_field_empty, 'prices cannot be an empty map')
		}

		ph.money_amounts = get_money_amounts_from_regional_prices(prices)!
	}

	return ph
}

// ProductVariantUpdateRequest describes a variant object used inside a product update payload.
//
// # Fields
//
// ## id
// Identifier of the variant to update within the product.
// If provided, updates the existing variant with that id.
// If omitted, creates a new variant.
//
// ## title
// Variant title (e.g., "Large/Red").
// If omitted, the variant title is not changed.
// If an empty string is provided, the variant title is deleted (set to empty).
//
// ## ean
// European Article Number (EAN) for the variant.
// If omitted, the EAN is not changed.
// If an empty string is provided, the EAN is deleted (set to empty).
//
// ## upc
// Universal Product Code (UPC) for the variant.
// If omitted, the UPC is not changed.
// If an empty string is provided, the UPC is deleted (set to empty).
//
// ## barcode
// Generic barcode field.
// If omitted, the barcode is not changed.
// If an empty string is provided, the barcode is deleted (set to empty).
//
// ## image
// Index of the product image related to the variant.
// If omitted, the image is not changed.
// To remove the relation, delete the related image.
//
// ## inventory_item
// See InventoryItemUpdateRequest.
// If omitted, inventory fields are not changed.
//
// ## option_values
// Array of integers that maps this variant to option values by option position.
// If provided, it replaces the variant's existing option value mapping.
// - The array must contain exactly one element per product option.
// - The element index represents the option index, while the element value represents the value index.
// - Example: `option_values: [2, 0, 1]` → option index 0 uses value index 2, option index 1 uses value index 0, option index 2 uses value index 1.
// If omitted, the variant's option values remain unchanged.
//
// ## metadata
// Raw metadata stored as a string. Use for arbitrary user-defined data.
// If omitted, metadata is not changed.
// If an empty string is provided, metadata is deleted (set to empty).
//
// ## money_amounts
// Optional array of region money amounts for this variant.
// When provided:
// - For each region, there must be at least one money amount with `is_original` set to `false` or omitted (the base price).
// - For each region, there may be at most one money amount with `is_original` set to `true` (the original price).
// - If a previously stored original price for a region is not included, that original price will be removed.
// When omitted, `money_amounts` are not changed.
pub struct ProductVariantUpdateRequest {
pub:
	id              ?string
	title           ?string
	ean             ?string
	upc             ?string
	barcode         ?string
	image           ?i32
	inventory_item  ?InventoryItemUpdateRequest     @[json: 'inventoryItem']
	option_values   ?[]i32                          @[json: 'optionValues']
	metadata        ?string                         @[raw]
	regional_prices ?map[string]VariantPriceRequest @[json: 'regionalPrices']
}

struct ProductVariantUpdateRequestHygienised {
	id             ?ID
	title          ?string
	ean            ?string
	upc            ?string
	barcode        ?string
	image          ?i32
	inventory_item ?InventoryItemUpdateRequestHygienised
	option_values  ?[]i32
	metadata       ?string
mut:
	money_amounts ?[]VariantMoneyAmountRequestHygienised
}

fn (p ProductVariantUpdateRequest) hygienise() !ProductVariantUpdateRequestHygienised {
	mut parsed_id := ?ID(none)
	if id := p.id {
		parsed_id = id_from_string(id) or {
			return errors.unprocessable_entity(error_id_invalid, 'id')
		}
	}

	if ean := p.ean {
		if utf8_str_visible_length(ean) > max_length_ean {
			return errors.bad_request(error_field_too_long, format_field_too_long_details('ean',
				max_length_ean))
		}
	}

	if upc := p.upc {
		if utf8_str_visible_length(upc) > max_length_upc {
			return errors.bad_request(error_field_too_long, format_field_too_long_details('upc',
				max_length_upc))
		}
	}

	if barcode := p.barcode {
		if utf8_str_visible_length(barcode) > max_length_barcode {
			return errors.bad_request(error_field_too_long, format_field_too_long_details('barcode',
				max_length_barcode))
		}
	}

	mut inventory_item := InventoryItemUpdateRequestHygienised{}
	if ii := p.inventory_item {
		inventory_item = ii.hygienise()!
	}

	if option_values := p.option_values {
		if option_values.len == 0 {
			return errors.unprocessable_entity(error_field_empty,
				'A variant must reference at least one option')
		}
	}

	mut ph := ProductVariantUpdateRequestHygienised{
		id:             parsed_id
		title:          p.title
		ean:            p.ean
		upc:            p.upc
		barcode:        p.barcode
		image:          p.image
		inventory_item: inventory_item
		option_values:  p.option_values
		metadata:       p.metadata
	}

	if prices := p.regional_prices {
		if prices.len == 0 {
			errors.bad_request(error_field_empty, 'prices cannot be an empty map')
		}

		ph.money_amounts = get_money_amounts_from_regional_prices(prices)!
	}

	return ph
}

// VariantCreateRequest describes the body of the request to create a new product variant.
//
// # Fields
//
// ## title
// Variant title (e.g., "Large", "Red").
//
// ## ean
// European Article Number (EAN) for the variant.
//
// ## upc
// Universal Product Code (UPC) for the variant.
//
// ## barcode
// Generic barcode field.
//
// ## image_id
// The id of the product image related to the variant.
//
// ## inventory_item
// See InventoryItemCreateRequest.
//
// ## option_value_ids
// Required. Array of option value identifiers that define this variant (one id per product option).
// The combination of option_value_ids must uniquely identify the variant within the product.
// Each id must reference existing product option values.
//
// ## metadata
// Raw metadata stored as a string. Use for arbitrary user-defined data.
//
// ## regional_prices
// Optional regional prices for this variant.
// When provided:
// - For each region, there must be a base_price.
// - For each region, there may be an original_price.
// When omitted, all regional base_price will be initialized to a default value of 0.
pub struct VariantCreateRequest {
pub:
	title            ?string
	ean              ?string
	upc              ?string
	barcode          ?string
	image_id         ?string                         @[json: 'imageId']
	inventory_item   ?InventoryItemCreateRequest     @[json: 'inventoryItem']
	option_value_ids []string                        @[json: 'optionValueIds']
	metadata         ?string                         @[raw]
	regional_prices  ?map[string]VariantPriceRequest @[json: 'regionalPrices']
}

struct VariantCreateRequestHygienised {
	title            ?string
	ean              ?string
	upc              ?string
	barcode          ?string
	image_id         ?ID
	option_value_ids []ID
	metadata         ?string
mut:
	money_amounts  ?[]VariantMoneyAmountRequestHygienised
	inventory_item ?InventoryItemCreateRequestHygienised
}

fn (p VariantCreateRequest) hygienise() !VariantCreateRequestHygienised {
	if p.option_value_ids.len == 0 {
		return errors.unprocessable_entity(error_field_empty,
			'option_value_ids cannot be an empty array')
	}

	mut parsed_option_value_ids := []ID{len: p.option_value_ids.len}
	for i := 0; i < p.option_value_ids.len; i++ {
		id := p.option_value_ids[i]
		parsed_option_value_ids[i] = id_from_string(id) or {
			return errors.unprocessable_entity(error_id_invalid, 'option_value_ids')
		}
	}

	mut parsed_image_id := ?ID(none)
	if id := p.image_id {
		parsed_image_id = id_from_string(id) or {
			return errors.unprocessable_entity(error_id_invalid, 'image_id')
		}
	}

	mut ph := VariantCreateRequestHygienised{
		title:            p.title
		ean:              p.ean
		upc:              p.upc
		barcode:          p.barcode
		image_id:         parsed_image_id
		option_value_ids: parsed_option_value_ids
		metadata:         p.metadata
	}

	if prices := p.regional_prices {
		if prices.len == 0 {
			errors.bad_request(error_field_empty, 'prices cannot be an empty map')
		}

		ph.money_amounts = get_money_amounts_from_regional_prices(prices)!
	}

	if inventory_item := p.inventory_item {
		ph.inventory_item = inventory_item.hygienise()!
	}

	return ph
}

// VariantUpdateRequest describes the body of the request to update an existing product variant.
//
// # Fields
//
// ## title
// Variant title, typically a combination of option value names (e.g., "Large/Red").
// If an empty string is provided, the variant title is deleted.
// If omitted, the variant title is not changed.
//
// ## ean
// European Article Number (EAN) for the variant.
// If an empty string is provided, the EAN is deleted.
// If omitted, the EAN is not changed.
//
// ## upc
// Universal Product Code (UPC) for the variant.
// If an empty string is provided, the UPC is deleted.
// If omitted, the UPC is not changed.
//
// ## barcode
// Generic barcode field.
// If an empty string is provided, the barcode is deleted.
// If omitted, the barcode is not changed.
//
// ## image_id
// The id of the product image related to the variant.
// If omitted, the image is not changed.
// To remove the relation, delete the related image.
//
// ## inventory_item
// See InventoryItemUpdateRequest.
// If omitted, inventory fields are not changed.
//
// ## option_value_ids
// Optional. Array of option value identifiers that define this variant (one id per product option).
// If provided, it replaces the variant's existing option values and follows the same rules as creation:
// - The combination of option_value_ids must uniquely identify the variant within the product.
// - Each id must reference an existing product option value.
// If omitted, the variant's option values remain unchanged.
//
// ## metadata
// Raw metadata stored as a string. Use for arbitrary user-defined data.
// If an empty string is provided, the metadata is deleted.
// If omitted, metadata is not changed.
//
// ## regional_prices
// Optional regional prices for this variant.
// When provided:
// - For each region, there must be a base_price.
// - For each region, there may be an original_price.
// When omitted, regional prices are not changed.
pub struct VariantUpdateRequest {
pub:
	title            ?string
	ean              ?string
	upc              ?string
	barcode          ?string
	image_id         ?string                         @[json: 'imageId']
	inventory_item   ?InventoryItemUpdateRequest     @[json: 'inventoryItem']
	option_value_ids ?[]string                       @[json: 'optionValueIds']
	metadata         ?string                         @[raw]
	regional_prices  ?map[string]VariantPriceRequest @[json: 'regionalPrices']
}

struct VariantUpdateRequestHygienised {
	title            ?string
	ean              ?string
	upc              ?string
	barcode          ?string
	image_id         ?ID
	option_value_ids ?[]ID
	metadata         ?string
mut:
	inventory_item ?InventoryItemUpdateRequestHygienised
	money_amounts  ?[]VariantMoneyAmountRequestHygienised
}

fn (p VariantUpdateRequest) hygienise() !VariantUpdateRequestHygienised {
	mut parsed_option_value_ids := ?[]ID(none)
	if ids := p.option_value_ids {
		parsed_option_value_ids = ids_from_array_string(ids) or {
			return errors.unprocessable_entity(error_id_invalid, 'option_value_ids')
		}
	}

	mut parsed_image_id := ?ID(none)
	if id := p.image_id {
		parsed_image_id = id_from_string(id) or {
			return errors.unprocessable_entity(error_id_invalid, 'image_id')
		}
	}

	mut ph := VariantUpdateRequestHygienised{
		title:            p.title
		ean:              p.ean
		upc:              p.upc
		barcode:          p.barcode
		image_id:         parsed_image_id
		option_value_ids: parsed_option_value_ids
		metadata:         p.metadata
	}

	if prices := p.regional_prices {
		if prices.len == 0 {
			errors.bad_request(error_field_empty, 'prices cannot be an empty map')
		}

		ph.money_amounts = get_money_amounts_from_regional_prices(prices)!
	}

	if inventory_item := p.inventory_item {
		ph.inventory_item = inventory_item.hygienise()!
	}

	return ph
}

// By default, taxes are automatically calculated by peony during checkout. This behavior can be disabled
// for a region to limit the requests being sent to a tax provider.
pub struct RegionCreateRequest {
pub:
	name               string
	currency_code      string   @[json: 'currencyCode']
	includes_tax       ?bool    @[json: 'includesTax']
	gift_cards_taxable ?bool    @[json: 'giftCardsTaxable']
	automatic_taxes    ?bool    @[json: 'automaticTaxes']
	country_codes      []string @[json: 'countryCodes']
	//  taxes
}

fn hygienise_region_create_request(s string, region_id ID) !conduit.RegionCreateParams {
	p := json.decode(RegionCreateRequest, s) or {
		return errors.bad_request('Could not decode RegionCreateRequest', err.msg())
	}

	if p.name == '' {
		return errors.bad_request(error_field_empty, 'name')
	}

	if utf8_str_visible_length(p.name) > max_length_region_name {
		return errors.bad_request(error_field_invalid,
			'name cannot be longer than ${max_length_region_name} characters. Received `${p.name}`')
	}

	if p.currency_code == '' {
		return errors.bad_request(error_field_empty, 'currency_code')
	}

	if utf8_str_visible_length(p.currency_code) != currency_code_length {
		return errors.bad_request(error_field_invalid,
			'currency_code must be ${currency_code_length} characters long. Received `${p.currency_code}`')
	}

	if p.country_codes.len == 0 {
		return errors.bad_request(error_empty_object, 'country_codes')
	}

	for i := 0; i < p.country_codes.len; i++ {
		code := p.country_codes[i]
		if utf8_str_visible_length(code) != country_code_length {
			return errors.bad_request(error_field_invalid,
				'country_code must be ${country_code_length} characters long. Received `${code}`')
		}
	}

	return conduit.RegionCreateParams{
		id:                 region_id
		name:               p.name
		currency_code:      p.currency_code
		includes_tax:       bool_or(p.includes_tax, region_default_includes_tax)
		gift_cards_taxable: bool_or(p.gift_cards_taxable, region_default_gift_cards_taxable)
		automatic_taxes:    bool_or(p.automatic_taxes, region_default_automatic_taxes)
		country_codes:      p.country_codes
	}
}

pub struct RegionUpdateRequest {
pub:
	name               ?string
	currency_code      ?string   @[json: 'currencyCode']
	includes_tax       ?bool     @[json: 'includesTax']
	gift_cards_taxable ?bool     @[json: 'giftCardsTaxable']
	automatic_taxes    ?bool     @[json: 'automaticTaxes']
	country_codes      ?[]string @[json: 'countryCodes']
	//  taxes
}

fn hygienise_region_update_request(s string, region_id ID) !conduit.RegionUpdateParams {
	p := json.decode(RegionUpdateRequest, s) or {
		return errors.bad_request('Could not decode RegionUpdateRequest', err.msg())
	}

	if name := p.name {
		if name == '' {
			return errors.bad_request(error_field_empty, 'name')
		}

		if utf8_str_visible_length(name) > max_length_region_name {
			return errors.bad_request(error_field_invalid,
				'name cannot be longer than ${max_length_region_name} characters. Received `${name}`')
		}
	}

	if currency_code := p.currency_code {
		if currency_code == '' {
			return errors.bad_request(error_field_empty, 'currency_code')
		}

		if utf8_str_visible_length(currency_code) != currency_code_length {
			return errors.bad_request(error_field_invalid,
				'currency_code must be ${currency_code_length} characters long. Received `${currency_code}`')
		}
	}

	if country_codes := p.country_codes {
		if country_codes.len == 0 {
			return errors.bad_request(error_empty_object, 'country_codes')
		}

		for i := 0; i < country_codes.len; i++ {
			code := country_codes[i]
			if utf8_str_visible_length(code) != country_code_length {
				return errors.bad_request(error_field_invalid,
					'country_code must be ${country_code_length} characters long. Received `${code}`')
			}
		}
	}

	return conduit.RegionUpdateParams{
		id:                 region_id
		name:               p.name
		currency_code:      p.currency_code
		includes_tax:       p.includes_tax
		gift_cards_taxable: p.gift_cards_taxable
		automatic_taxes:    p.automatic_taxes
		country_codes:      p.country_codes
	}
}

pub struct CategoryTranslationRequest {
pub:
	name        ?string
	description ?string
}

fn hygienise_category_translations(p map[string]CategoryTranslationRequest) ![]conduit.CategoryTranslationParams {
	mut res := []conduit.CategoryTranslationParams{len: p.len}
	mut i := 0
	for locale_id, translation in p {
		parsed_locale_id := id_from_string(locale_id) or {
			return errors.unprocessable_entity(error_id_invalid, 'locale_id')
		}

		res[i] = conduit.CategoryTranslationParams{
			locale_id:   parsed_locale_id
			name:        translation.name
			description: translation.description
		}
		i++
	}
	return res
}

pub struct SEOTranslationRequest {
pub:
	title       ?string
	description ?string
}

struct SEOTranslationRequestHygienised {
	locale_id   ID
	title       ?string
	description ?string
}

fn hygienise_seo_translations(p map[string]SEOTranslationRequest) ![]conduit.SEOTranslationParams {
	mut res := []conduit.SEOTranslationParams{len: p.len}
	mut i := 0
	for locale_id, translation in p {
		parsed_locale_id := id_from_string(locale_id) or {
			return errors.unprocessable_entity(error_id_invalid, 'locale_id')
		}

		res[i] = conduit.SEOTranslationParams{
			locale_id:   parsed_locale_id
			title:       translation.title
			description: translation.description
		}
		i++
	}
	return res
}

fn (r SEOTranslationRequestHygienised) locale_id() ID {
	return r.locale_id
}

// SEORequest describes the body of the request to create SEO metadata.
//
// # Fields
//
// ## title
// The SEO title. If provided as an empty string, the existing title is removed.
//
// ## description
// The SEO description. If provided as an empty string, the existing description is removed.
//
// ## translations
// Localized versions of seo fields. The keys of the map are the locale id.
// To remove all translations, submit an empty object.
pub struct SEORequest {
pub:
	title        ?string
	description  ?string
	translations ?map[string]SEOTranslationRequest
}

fn (p SEORequest) hygienise() !conduit.SEOParams {
	if p.title == none && p.description == none && p.translations == none {
		return errors.unprocessable_entity(error_empty_object, 'SEORequest')
	}

	mut translations := ?[]conduit.SEOTranslationParams(none)
	if t := p.translations {
		translations = hygienise_seo_translations(t)!
	}

	return conduit.SEOParams{
		title:        p.title
		description:  p.description
		translations: translations
	}
}

// CategoryCreateRequest describes the body of the request to create a new category.
//
// # Fields
//
// ## name
// Category name. Required.
//
// ## description
// Category description.
//
// ## handle
// Category handle. If not provided, a new handle will be derived from the name.
//
// ## translations
// Localized versions of category fields. The keys of the map are the locale id.
//
// ## seo
// SEO metadata.
pub struct CategoryCreateRequest {
pub:
	name               string
	description        ?string
	handle             ?string
	is_internal        ?bool   @[json: 'isInternal']
	is_active          ?bool   @[json: 'isActive']
	parent_category_id ?string @[json: 'parentCategoryId']
	metadata           ?string @[raw]
	translations       ?map[string]CategoryTranslationRequest
	seo                ?SEORequest
}

fn hygienise_category_create_request(s string, category_id ID) !conduit.CategoryCreateParams {
	p := json.decode(CategoryCreateRequest, s) or {
		return errors.bad_request('Could not decode CategoryCreateRequest', err.msg())
	}

	mut parsed_parent_category_id := ?ID(none)
	if id := p.parent_category_id {
		parsed_parent_category_id = id_from_string(id) or {
			return errors.bad_request(error_id_invalid, 'parent_category_id')
		}
	}

	if utf8_str_visible_length(p.name) > max_length_category_name {
		return errors.unprocessable_entity(error_field_too_long, 'name')
	}

	if description := p.description {
		if utf8_str_visible_length(description) > max_length_category_description {
			return errors.unprocessable_entity(error_field_too_long, 'description')
		}
	}

	if handle := p.handle {
		if utf8_str_visible_length(handle) > max_length_handle {
			return errors.unprocessable_entity(error_field_too_long, 'handle')
		}
	}

	mut seo := ?conduit.SEOParams(none)
	if o := p.seo {
		seo = o.hygienise()!
	}

	mut translations := ?[]conduit.CategoryTranslationParams(none)
	if t := p.translations {
		translations = hygienise_category_translations(t)!
	}

	return conduit.CategoryCreateParams{
		id:                 category_id
		name:               p.name
		handle:             p.handle
		description:        p.description
		is_active:          bool_or(p.is_active, category_default_is_active)
		is_internal:        bool_or(p.is_internal, category_default_is_internal)
		parent_category_id: parsed_parent_category_id
		metadata:           p.metadata
		translations:       translations
		seo:                seo
	}
}

// CategoryUpdateRequest describes the body of the request to update an existing category.
//
// # Fields
//
// ## name
// Category name. If provided, it must not be empty.
//
// ## description
// Category description. If provided as an empty string, the existing description is removed.
//
// ## handle
// Category handle. If provided as an empty string, a new handle will be derived from the name.
//
// ## translations
// Localized versions of category fields. The keys of the map are the locale id.
// To remove all translations, submit an empty object.
//
// ## seo
// SEO metadata.
pub struct CategoryUpdateRequest {
pub:
	name               ?string
	description        ?string
	handle             ?string
	is_internal        ?bool   @[json: 'isInternal']
	is_active          ?bool   @[json: 'isActive']
	parent_category_id ?string @[json: 'parentCategoryId']
	metadata           ?string @[raw]
	translations       ?map[string]CategoryTranslationRequest
	seo                ?SEORequest
}

fn hygienise_category_update_request(s string, category_id ID) !conduit.CategoryUpdateParams {
	p := json.decode(CategoryUpdateRequest, s) or {
		return errors.bad_request('Could not decode CategoryUpdateRequest', err.msg())
	}

	if p.name == none && p.description == none && p.handle == none && p.is_internal == none
		&& p.is_active == none && p.parent_category_id == none && p.metadata == none
		&& p.translations == none && p.seo == none {
		return errors.bad_request(error_empty_object, 'CategoryUpdateRequest')
	}

	mut parsed_parent_category_id := ?ID(none)
	if id := p.parent_category_id {
		parsed_parent_category_id = id_from_string(id) or {
			return errors.bad_request(error_id_invalid, 'parent_category_id')
		}
	}

	if name := p.name {
		if utf8_str_visible_length(name) > max_length_category_name {
			return errors.unprocessable_entity(error_field_too_long, 'name')
		}
	}

	if description := p.description {
		if utf8_str_visible_length(description) > max_length_category_description {
			return errors.unprocessable_entity(error_field_too_long, 'description')
		}
	}

	if handle := p.handle {
		if utf8_str_visible_length(handle) > max_length_handle {
			return errors.unprocessable_entity(error_field_too_long, 'handle')
		}
	}

	mut seo := ?conduit.SEOParams(none)
	if o := p.seo {
		seo = o.hygienise()!
	}

	mut translations := ?[]conduit.CategoryTranslationParams(none)
	if t := p.translations {
		translations = hygienise_category_translations(t)!
	}

	return conduit.CategoryUpdateParams{
		id:                 category_id
		name:               p.name
		handle:             p.handle
		description:        p.description
		is_active:          p.is_active
		is_internal:        p.is_internal
		parent_category_id: parsed_parent_category_id
		metadata:           p.metadata
		translations:       translations
		seo:                seo
	}
}

// ProductCreateRequest describes the body of the request to create a new product.
//
// # Fields
//
// ## title
// Product title in the store's default locale.
//
// ## subtitle
// Product subtitle in the default locale.
//
// ## description
// Product description in the default locale.
//
// ## handle
// Product handle. If omitted, one will be generated automatically.
//
// ## is_giftcard
// Whether the product is a gift card.
//
// ## status
// See constants: `product_status_draft`, `product_status_proposed`, `product_status_published`, `product_status_rejected`.
//
// ## discountable
// Whether the product is eligible for discounts.
//
// ## metadata
// Raw metadata stored as a string.
//
// ## sales_channel_ids
// Sales channels where the product will be available.
//
// ## category_ids
// Categories the product belongs to.
//
// ## translations
// Localized versions of product fields. The keys of the map are the locale id.
// To remove all translations, submit an empty object.
//
// ## seo
// SEO metadata.
//
// ## options
// Product options (e.g. size, color).
// The array order is preserved.
// An empty array is treated as an explicit empty value and rejected.
// If omitted, peony creates a default option.
// If provided, variants must also be provided.
//
// ## variants
// The array order is preserved.
// An empty array is treated as an explicit empty value and rejected.
// All variants must reference all options.
// All variants must have a unique combination of option values.
// If omitted and options is omitted, one default variant will be created using the default option.
// If one variant is provided and options is omitted, the default variant will be created according to the data of the provided element.
//
// ## thumbnail
// Index of the thumbnail image within the `images` array.
// If omitted, the first image in `images` is used.
// If `images` is empty or omitted, the product is created without a thumbnail.
//
// ## images
// Images to associate with the product.
// Array order is preserved.
pub struct ProductCreateRequest {
pub:
	title             string
	subtitle          ?string
	description       ?string
	handle            ?string
	is_giftcard       ?bool @[json: 'isGiftcard']
	status            ?string
	discountable      ?bool
	metadata          ?string   @[raw]
	sales_channel_ids ?[]string @[json: 'salesChannelIds']
	category_ids      ?[]string @[json: 'categoryIds']
	translations      ?map[string]ProductTranslationRequest
	seo               ?SEORequest
	options           ?[]ProductOptionCreateRequest
	variants          ?[]ProductVariantCreateRequest
	thumbnail         ?i32
	images            ?[]ImageCreateRequest
	// type_id           ?string @[json: 'typeId']
	// tag_ids           ?[]string @[json: 'tagIds']
}

struct ProductCreateRequestHygienised {
	title             string
	subtitle          ?string
	description       ?string
	handle            ?string
	is_giftcard       ?bool
	status            ?string
	discountable      ?bool
	metadata          ?string
	sales_channel_ids ?[]ID
	category_ids      ?[]ID
	thumbnail         ?i32
	// type_id               ?ID
	// tag_ids               ?[]ID
mut:
	seo          ?SEORequestHygienised
	options      ?[]ProductOptionCreateRequestHygienised
	variants     ?[]ProductVariantCreateRequestHygienised
	translations ?[]ProductTranslationRequestHygienised
	images       ?[]ImageCreateRequestHygienised
}

fn (p ProductCreateRequestHygienised) validate_variants_reference_all_options() ! {
	options := p.options or { return }
	variants := p.variants or { return }

	// each variant must reference all options
	for i := 0; i < variants.len; i++ {
		variant := variants[i]
		option_values := variant.option_values or {
			return errors.unprocessable_entity(error_field_empty,
				'Each variant must reference all options with the option_values field')
		}

		if option_values.len != options.len {
			return errors.unprocessable_entity('option_values length does not match options length. Got ${option_values.len}, expected ${options.len}',
				'Each variant must reference all options')
		}
	}
}

fn (p ProductCreateRequestHygienised) validate_no_orphan_option_values() ! {
	variants := p.variants or { return }
	for i := 0; i < variants.len; i++ {
		variant := variants[i]
		if variant.option_values == none {
			continue
		}

		if p.options == none {
			return errors.unprocessable_entity(error_field_empty,
				'option_values cannot be provided because no options are defined')
		}
	}
}

fn (p ProductCreateRequestHygienised) validate_no_too_many_variants() ! {
	variants := p.variants or { return }
	if variants.len < 2 {
		return
	}

	options := p.options or {
		return errors.unprocessable_entity(error_field_empty,
			'Empty `options` field not allowed: an option must be created in order to create variants')
	}

	mut possible_combinations := 1
	for i := 0; i < options.len; i++ {
		option := options[i]
		possible_combinations *= option.values.len
	}

	if variants.len > possible_combinations {
		return errors.unprocessable_entity('too_many_variants',
			'Provided ${variants.len} variants but there can only be ${possible_combinations} possible combinations with the provided options and values.')
	}
}

fn (p ProductCreateRequestHygienised) validate_no_duplicate_variants() ! {
	variants := p.variants or { return }
	if variants.len < 2 {
		return
	}

	mut seen_combinations := map[string]bool{}
	for i := 0; i < variants.len; i++ {
		variant := variants[i]
		option_values := variant.option_values or {
			return errors.unprocessable_entity(error_field_empty,
				'Empty option_values field not allowed: each variant must reference all options')
		}

		mut combination := ''
		for option_index := 0; option_index < option_values.len; option_index++ {
			value_index := option_values[option_index]

			if option_index == 0 {
				combination = '${value_index}'
			} else {
				combination = '${combination}-${value_index}'
			}
		}

		if seen_combinations[combination] {
			return errors.unprocessable_entity('Duplicate variant.',
				'2 variants have the same option values')
		}

		seen_combinations[combination] = true
	}
}

fn (p ProductCreateRequestHygienised) validate_variants_reference_valid_values() ! {
	variants := p.variants or { return }
	if variants.len < 2 {
		return
	}

	options := p.options or {
		return errors.unprocessable_entity(error_field_empty,
			'Empty `options` field not allowed: an option must be created in order to create variants')
	}

	for i := 0; i < variants.len; i++ {
		variant := variants[i]
		option_values := variant.option_values or {
			return errors.unprocessable_entity(error_field_empty,
				'Empty option_values field not allowed: each variant must reference all options')
		}

		for option_index := 0; option_index < option_values.len; option_index++ {
			option := options[option_index]
			value_index := option_values[option_index]
			max_value_index := option.values.len - 1
			if value_index < 0 {
				return errors.unprocessable_entity('Invalid value index.',
					'An index cannot be a negative integer')
			}

			if value_index > max_value_index {
				return errors.unprocessable_entity('Invalid value index. Got: ${value_index}, maximum allowed: ${max_value_index}',
					'The option at index ${option_index} contains an array of ${option.values.len} values (max index: ${max_value_index}), a value cannot have index ${value_index}.')
			}
		}
	}
}

// the request could contain one variant and no options, in which case a default option is created.
// the request may contain one variant and one option. In this case, references must be verified.
fn (p ProductCreateRequestHygienised) validate_one_variant_case() ! {
	variants := p.variants or { return }
	if variants.len != 1 {
		return
	}

	variant := variants[0]
	options := p.options or { return }

	option_values := variant.option_values or {
		return errors.unprocessable_entity(error_field_empty,
			'Empty option_values field not allowed: each variant must reference all options')
	}

	for option_index := 0; option_index < option_values.len; option_index++ {
		option := options[option_index]
		value_index := option_values[option_index]
		max_value_index := option.values.len - 1
		if value_index < 0 {
			return errors.unprocessable_entity('Invalid value index.',
				'An index cannot be a negative integer')
		}

		if value_index > max_value_index {
			return errors.unprocessable_entity('Invalid value index. Got: ${value_index}, maximum allowed: ${max_value_index}',
				'The option at index ${option_index} contains an array of ${option.values.len} values (max index: ${max_value_index}), a value cannot have index ${value_index}.')
		}
	}
}

fn (p ProductCreateRequestHygienised) validate_variant_image() ! {
	variants := p.variants or { return }
	for i := 0; i < variants.len; i++ {
		variant := variants[i]
		variant_image := variant.image or { continue }
		if variant_image < 0 {
			return errors.unprocessable_entity(error_reference_invalid,
				'The variant image index cannot be negative')
		}

		product_images := p.images or {
			return errors.unprocessable_entity(error_reference_invalid,
				'A variant image is defined but the product has no images. A variant image is a reference to a product image, therefore a variant cannot have an image if the product has no images.')
		}

		if variant_image >= product_images.len {
			return errors.unprocessable_entity(error_reference_invalid, 'Out of bounds:
				variant image: `${variant_image}`
				product_images.len: `${product_images.len}`')
		}
	}
}

fn (p ProductCreateRequest) hygienise() !ProductCreateRequestHygienised {
	if p.title == '' {
		return errors.unprocessable_entity(error_field_empty, 'title')
	}

	if utf8_str_visible_length(p.title) > max_length_product_title {
		return errors.unprocessable_entity(error_field_too_long, 'title')
	}

	if subtitle := p.subtitle {
		if utf8_str_visible_length(subtitle) > max_length_product_subtitle {
			return errors.unprocessable_entity(error_field_too_long, 'subtitle')
		}
	}

	if handle := p.handle {
		if utf8_str_visible_length(handle) > max_length_handle {
			return errors.unprocessable_entity(error_field_too_long, 'handle')
		}
	}

	if thumbnail := p.thumbnail {
		if thumbnail < 0 {
			return errors.unprocessable_entity('thumbnail invalid', 'negative value')
		}

		if images := p.images {
			if !(thumbnail < images.len) {
				return errors.unprocessable_entity('thumbnail invalid', 'index out of range')
			}
		} else {
			return errors.unprocessable_entity('thumbnail invalid', 'images array not provided')
		}
	}

	if status := p.status {
		if !product_status_is_valid(status) {
			return errors.unprocessable_entity('status is invalid', status)
		}
	}

	mut parsed_sales_channel_ids := ?[]ID(none)
	if ids := p.sales_channel_ids {
		parsed_sales_channel_ids = ids_from_array_string(ids) or {
			return errors.unprocessable_entity(error_id_invalid, 'sales_channel_ids')
		}
	}

	mut parsed_category_ids := ?[]ID(none)
	if ids := p.category_ids {
		parsed_category_ids = ids_from_array_string(ids) or {
			return errors.unprocessable_entity(error_id_invalid, 'category_ids')
		}
	}

	if options := p.options {
		// Reject creation of a product with 0 options
		if options.len == 0 {
			return errors.unprocessable_entity(error_field_empty,
				'A product must have at least one option.')
		}

		variants := p.variants or {
			return errors.unprocessable_entity(error_field_empty,
				'variants must be provided when options are specified')
		}

		if variants.len == 0 {
			return errors.unprocessable_entity(error_field_empty,
				'At least one variant must be provided when options are specified')
		}

		for i := 0; i < variants.len; i++ {
			variant := variants[i]
			option_values := variant.option_values or {
				return errors.unprocessable_entity(error_field_empty,
					'Each variant must reference all options. The variant at index `${i}` has no defined option_values')
			}

			if option_values.len != options.len {
				return errors.unprocessable_entity(error_reference_invalid,
					'Each variant must reference all options. The variant at index `${i}` references `${option_values.len}` options, but `${options.len}` options are defined.')
			}

			for j := 0; j < options.len; j++ {
				option := options[j]
				values := option.values
				value_index := option_values[j]
				if values.len <= value_index {
					return errors.unprocessable_entity(error_reference_invalid,
						'Out of bounds: the option at index `${j}` has a total of `${values.len}` values, there cannot be a value at index `${value_index}`')
				}
			}
		}
	}

	if variants := p.variants {
		// Reject creation of a product with 0 variants
		if variants.len == 0 {
			return errors.unprocessable_entity(error_field_explicit_empty,
				'A product must have at least one variant.')
		}

		if images := p.images {
			max_image_index := images.len - 1
			for i := 0; i < variants.len; i++ {
				variant := variants[i]
				if variant_image := variant.image {
					if variant_image < 0 {
						return errors.unprocessable_entity(error_reference_invalid,
							'Negative index')
					}

					if variant_image > max_image_index {
						return errors.unprocessable_entity(error_reference_invalid,
							'Out of bounds: the product has a total of ${images.len} images, but the variant references an image at index `${variant_image}`')
					}
				}
			}
		}
	}

	mut ph := ProductCreateRequestHygienised{
		title:             p.title
		subtitle:          p.subtitle
		description:       p.description
		handle:            p.handle
		is_giftcard:       p.is_giftcard
		status:            p.status
		thumbnail:         p.thumbnail
		discountable:      p.discountable
		metadata:          p.metadata
		sales_channel_ids: parsed_sales_channel_ids
		category_ids:      parsed_category_ids
	}

	if options := p.options {
		mut h := []ProductOptionCreateRequestHygienised{len: options.len}
		for i := 0; i < options.len; i++ {
			h[i] = options[i].hygienise()!
		}
		ph.options = h
	}

	if variants := p.variants {
		mut v := []ProductVariantCreateRequestHygienised{len: variants.len}
		for i := 0; i < variants.len; i++ {
			v[i] = variants[i].hygienise()!
		}
		ph.variants = v
	}

	if translations := p.translations {
		ph.translations = hygienise_product_translations(translations)!
	}

	if seo := p.seo {
		ph.seo = seo.hygienise()!
	}

	if images := p.images {
		mut h := []ImageCreateRequestHygienised{len: images.len}
		for i := 0; i < images.len; i++ {
			h[i] = images[i].hygienise()!
		}
		ph.images = h
	}

	ph.validate_no_orphan_option_values()!
	ph.validate_variants_reference_all_options()!
	ph.validate_one_variant_case()!
	ph.validate_variants_reference_valid_values()!
	ph.validate_no_too_many_variants()!
	ph.validate_no_duplicate_variants()!
	ph.validate_variant_image()!

	return ph
}

// ProductUpdateRequest describes the body of the request to update an existing product.
//
// # Fields
//
// ## title
// Product title. If provided, it must not be empty.
//
// ## subtitle
// Product subtitle. If provided as an empty string, the existing subtitle is removed.
//
// ## description
// Product description. If provided as an empty string, the existing description is removed.
//
// ## handle
// Product handle. If provided as an empty string, a new handle will be derived from the title.
//
// ## is_giftcard
// Whether the product is a gift card.
//
// ## status
// See constants: `product_status_draft`, `product_status_proposed`, `product_status_published`, `product_status_rejected`.
//
// ## discountable
// Whether the product is eligible for discounts.
//
// ## metadata
// Raw metadata stored as a string.
//
// ## sales_channel_ids
// Sales channels where the product will be available.
//
// ## category_ids
// Categories the product belongs to. To remove the product from all categories, submit an empty array.
//
// ## translations
// Localized versions of product fields. The keys of the map are the locale id.
//
// ## thumbnail
// Logic depends on the `images` field:
// - If `thumbnail` is provided and `images` is empty, the image whose `rank` equals `thumbnail` is used.
// - If both are provided, the thumbnail is the image at index `thumbnail` in the `images` array.
//
// ## images
// When provided, `images` is a replacement array for the product's images.
// - Items with an `id` are kept or updated.
// - Items without an `id` are created as new images.
// - Existing images omitted from this array are deleted.
// - The array order is preserved.
// - To remove all images, submit an empty array.
//
// ## seo
// SEO metadata for the product.
//
// ## options
// When provided, `options` is a replacement array for the product's options.
// - Items with `id` update that option, items without `id` are created.
// - Omitted existing options are removed. The last option cannot be removed.
// - The array index is preserved.
// - Each option may include a `values` array. When `values` is provided it replaces that option's values:
//   - Items with `id` update that value, items without `id` are created.
//   - Omitted existing values are removed.
//   - The index in the values array is the valueRank for that option.
//
// ## variants
// When provided, `variants` is a replacement array for the product's variants.
// - Items with `id` update that variant, items without `id` are created.
// - Omitted existing variants are removed. The last variant cannot be removed.
// - The array order is preserved.
// - Each variant must include an `optionValues` array:
//   - The index refers to the `optionRank`.
//   - Each entry refers to the `valueRank`.
pub struct ProductUpdateRequest {
pub:
	title             ?string
	subtitle          ?string
	description       ?string
	handle            ?string
	is_giftcard       ?bool @[json: 'isGiftcard']
	status            ?string
	discountable      ?bool
	metadata          ?string   @[raw]
	sales_channel_ids ?[]string @[json: 'salesChannelIds']
	category_ids      ?[]string @[json: 'categoryIds']
	translations      ?map[string]ProductTranslationRequest
	thumbnail         ?i32
	images            ?[]ImageUpdateRequest
	seo               ?SEORequest
	options           ?[]ProductOptionUpdateRequest
	variants          ?[]ProductVariantUpdateRequest
	// type_id           ?string @[json: 'typeId']
	// tag_ids           ?[]string @[json: 'tagIds']
}

struct ProductUpdateRequestHygienised {
	title             ?string
	subtitle          ?string
	description       ?string
	handle            ?string
	is_giftcard       ?bool
	status            ?string
	discountable      ?bool
	metadata          ?string
	sales_channel_ids ?[]ID
	category_ids      ?[]ID
	thumbnail         ?i32
mut:
	translations ?[]ProductTranslationRequestHygienised
	images       ?[]ImageUpdateRequestHygienised
	seo          ?SEORequestHygienised
	options      ?[]ProductOptionUpdateRequestHygienised
	variants     ?[]ProductVariantUpdateRequestHygienised
}

fn (p ProductUpdateRequest) hygienise() !ProductUpdateRequestHygienised {
	if title := p.title {
		if title == '' {
			return errors.unprocessable_entity(error_field_empty, 'title')
		}

		if utf8_str_visible_length(title) > max_length_product_title {
			return errors.unprocessable_entity(error_field_too_long, 'title')
		}
	}

	if subtitle := p.subtitle {
		if utf8_str_visible_length(subtitle) > max_length_product_subtitle {
			return errors.unprocessable_entity(error_field_too_long, 'subtitle')
		}
	}

	if handle := p.handle {
		if utf8_str_visible_length(handle) > max_length_handle {
			return errors.unprocessable_entity(error_field_too_long, 'handle')
		}
	}

	if thumbnail := p.thumbnail {
		if thumbnail < 0 {
			return errors.unprocessable_entity('thumbnail invalid', 'negative value')
		}

		if images := p.images {
			if !(thumbnail < images.len) {
				return errors.unprocessable_entity('thumbnail invalid', 'index out of range')
			}
		} else {
			return errors.unprocessable_entity('thumbnail invalid', 'images array not provided')
		}
	}

	if status := p.status {
		if !product_status_is_valid(status) {
			return errors.unprocessable_entity('status is invalid', status)
		}
	}

	mut parsed_sales_channel_ids := ?[]ID(none)
	if ids := p.sales_channel_ids {
		parsed_sales_channel_ids = ids_from_array_string(ids) or {
			return errors.unprocessable_entity(error_id_invalid, 'sales_channel_ids')
		}
	}

	mut parsed_category_ids := ?[]ID(none)
	if ids := p.category_ids {
		parsed_category_ids = ids_from_array_string(ids) or {
			return errors.unprocessable_entity(error_id_invalid, 'category_ids')
		}
	}

	if options := p.options {
		// Reject deleting all options
		if options.len == 0 {
			return errors.unprocessable_entity(error_field_empty,
				'A product must have at least one option.')
		}

		// When a new option is created, variants must be defined.
		mut has_new_options := false
		for i := 0; i < options.len; i++ {
			option := options[i]
			if option.id == none {
				has_new_options = true
				break
			}
		}

		if has_new_options && p.variants == none {
			return errors.unprocessable_entity(error_field_empty,
				'variants must be provided when new options are specified')
		}

		if variants := p.variants {
			// reject deleting all variants
			if variants.len == 0 {
				return errors.unprocessable_entity(error_field_empty,
					'A product must have at least one variant')
			}

			for i := 0; i < variants.len; i++ {
				variant := variants[i]
				option_values := variant.option_values or {
					return errors.unprocessable_entity(error_field_empty,
						'Each variant must reference all options. The variant at index `${i}` has no defined option_values')
				}

				if option_values.len != options.len {
					return errors.unprocessable_entity(error_reference_invalid,
						'Each variant must reference all options. The variant at index `${i}` references `${option_values.len}` options, but `${options.len}` options are defined.')
				}

				for j := 0; j < options.len; j++ {
					option := options[j]
					values := option.values or {
						if variant.id == none {
							return errors.unprocessable_entity(error_field_empty,
								'A new variant must reference all product options. The variant at index `${j}` has no option_values.')
						}
						continue
					}

					value_index := option_values[j]
					if values.len <= value_index {
						return errors.unprocessable_entity(error_reference_invalid,
							'Out of bounds: the option at index `${j}` has a total of `${values.len}` values, there cannot be a value at index `${value_index}`')
					}
				}
			}
		}
	}

	mut ph := ProductUpdateRequestHygienised{
		title:             p.title
		subtitle:          p.subtitle
		description:       p.description
		handle:            p.handle
		is_giftcard:       p.is_giftcard
		status:            p.status
		discountable:      p.discountable
		metadata:          p.metadata
		sales_channel_ids: parsed_sales_channel_ids
		category_ids:      parsed_category_ids
		thumbnail:         p.thumbnail
	}

	if translations := p.translations {
		ph.translations = hygienise_product_translations(translations)!
	}

	if images := p.images {
		mut h := []ImageUpdateRequestHygienised{len: images.len}
		for i := 0; i < images.len; i++ {
			h[i] = images[i].hygienise()!
		}
		ph.images = h
	}

	if seo := p.seo {
		ph.seo = seo.hygienise()!
	}

	if options := p.options {
		mut o := []ProductOptionUpdateRequestHygienised{len: options.len}
		for i := 0; i < options.len; i++ {
			o[i] = options[i].hygienise()!
		}
		ph.options = o
	}

	if variants := p.variants {
		mut v := []ProductVariantUpdateRequestHygienised{len: variants.len}
		for i := 0; i < variants.len; i++ {
			v[i] = variants[i].hygienise()!
		}
		ph.variants = v
	}

	return ph
}
