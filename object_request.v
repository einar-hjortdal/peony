module peony

pub struct AuthRequest {
pub:
	email    string
	password string
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

struct StoreUpdateRequestHygienised {
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
}

fn hygienise_store_request(p StoreUpdateRequest) !StoreUpdateRequestHygienised {
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

	return StoreUpdateRequestHygienised{
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

// TODO check alt.len <= 191
fn (i ImageTranslationRequest) hygienise() !ImageTranslationRequestHygienised {
	locale_id_bin := id_string_to_bin(i.locale_id) or {
		return new_internal_error(error_id_invalid, 'locale_id')
	}

	if i.alt == '' {
		return new_internal_error(error_field_empty, 'alt')
	}

	if utf8_str_visible_length(i.alt) > max_length_alt {
		return new_internal_error('alt too long', 'alt can be at most ${max_length_alt} UTF8 characters long')
	}

	return ImageTranslationRequestHygienised{
		locale_id:     i.locale_id
		locale_id_bin: locale_id_bin
		alt:           i.alt
	}
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
// Localized versions of image fields. To remove all translations, submit an empty array.
pub struct ImageCreateRequest {
pub:
	url          string
	alt          ?string
	translations ?[]ImageTranslationRequest
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
			return new_internal_error('alt too long', 'alt can be at most ${max_length_alt} UTF8 characters long')
		}
	}

	mut image := ImageCreateRequestHygienised{
		url: p.url
		alt: p.alt
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
// Localized versions of image fields. If omitted during update, existing translations are preserved.
// To remove all translations, submit an empty array.
pub struct ImageUpdateRequest {
pub:
	id           ?string
	url          ?string
	alt          ?string
	translations ?[]ImageTranslationRequest
}

struct ImageUpdateRequestHygienised {
	id     ?string
	id_bin []u8
	url    ?string
	alt    ?string
mut:
	translations ?[]ImageTranslationRequestHygienised
}

fn (p ImageUpdateRequest) hygienise() !ImageUpdateRequestHygienised {
	if p.id != none && p.url != none {
		return new_internal_error('unable to update image url', 'both id and url are set')
	}

	if p.id == none && p.url == none {
		return new_internal_error('unable to create image without url', 'both id and url are unset')
	}

	if alt := p.alt {
		if utf8_str_visible_length(alt) > max_length_alt {
			return new_internal_error('alt too long', 'alt can be at most ${max_length_alt} UTF8 characters long')
		}
	}

	mut image := ImageUpdateRequestHygienised{
		id:     p.id
		id_bin: option_id_string_to_id_bin(p.id)!
		url:    p.url
		alt:    p.alt
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
	image      ?ImageCreateRequest
	metadata   ?string @[raw]
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

fn (p ProductTranslationRequest) hygienise() !ProductTranslationRequestHygienised {
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
	name         string
	translations ?[]ProductOptionValueTranslationRequest
}

struct ProductOptionValueRequestHygienised {
	name string
mut:
	translations ?[]ProductOptionValueTranslationRequestHygienised
}

fn (p ProductOptionValueRequest) hygienise() !ProductOptionValueRequestHygienised {
	mut res := ProductOptionValueRequestHygienised{
		name: p.name
	}

	if translations := p.translations {
		mut ts := []ProductOptionValueTranslationRequestHygienised{len: translations.len}
		for i := 0; i < translations.len; i++ {
			ts[i] = translations[i].hygienise()!
		}
	}

	return res
}

// verifies:
// name is not empty
// TODO all locale_id exist
fn (p ProductOptionValueRequestHygienised) verify() ! {
	if p.name == '' {
		return new_internal_error(error_field_empty, 'name')
	}

	if translations := p.translations {
		if translations.len == 0 {
			return new_internal_error(error_field_empty, 'translations')
		}
	}
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
	translations ?[]ProductOptionValueTranslationRequest
}

struct ProductOptionValueUpdateRequestHygienised {
	id     ?string
	id_bin []u8
	name   ?string
mut:
	translations ?[]ProductOptionValueTranslationRequestHygienised
}

fn (p ProductOptionValueUpdateRequest) hygienise() !ProductOptionValueUpdateRequestHygienised {
	if p.name == none && p.translations == none {
		return new_internal_error(error_empty_object, 'ProductOptionValueUpdateRequest')
	}

	mut res := ProductOptionValueUpdateRequestHygienised{
		name: p.name
	}

	if translations := p.translations {
		mut ts := []ProductOptionValueTranslationRequestHygienised{len: translations.len}
		for i := 0; i < translations.len; i++ {
			ts[i] = translations[i].hygienise()!
		}
	}

	return res
}

fn (p ProductOptionValueUpdateRequestHygienised) verify() ! {
	if name := p.name {
		if name == '' {
			return new_internal_error(error_field_empty, 'name')
		}
	}

	if translations := p.translations {
		if translations.len == 0 {
			return new_internal_error(error_field_empty, 'translations')
		}
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
	title        string
	translations ?[]ProductOptionTranslationRequest
	values       []ProductOptionValueRequest
}

struct ProductOptionCreateRequestHygienised {
	title  string
	values []ProductOptionValueRequestHygienised
mut:
	translations ?[]ProductOptionTranslationRequestHygienised
}

fn (p ProductOptionCreateRequest) hygienise() !ProductOptionCreateRequestHygienised {
	mut values := []ProductOptionValueRequestHygienised{len: p.values.len}
	for i := 0; i < p.values.len; i++ {
		values[i] = p.values[i].hygienise()!
	}

	mut res := ProductOptionCreateRequestHygienised{
		title:  p.title
		values: values
	}

	if translations := p.translations {
		mut ts := []ProductOptionTranslationRequestHygienised{len: translations.len}
		for i := 0; i < translations.len; i++ {
			ts[i] = translations[i].hygienise()!
		}
		res.translations = ts
	}

	return res
}

// verifies:
// All locale_id exist TODO
// The product_option has at least one value
fn (p ProductOptionCreateRequestHygienised) verify() ! {
	if p.title == '' {
		return new_internal_error(error_field_empty, 'title')
	}

	option_values := p.values

	if translations := p.translations {
		if translations.len == 0 {
			return new_internal_error(error_field_empty, 'translations')
		}
	}

	if option_values.len == 0 {
		return new_internal_error(error_field_empty, 'The product_option lacks values, at least one value must be provided.')
	}

	for i := 0; i < option_values.len; i++ {
		option_values[i].verify()!
	}
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
// When provided, `translations` is a replacement array for the option's translations.
// If omitted, translations are left unchanged.
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
	translations ?[]ProductOptionTranslationRequest
	values       ?[]ProductOptionValueUpdateRequest
}

struct ProductOptionUpdateRequestHygienised {
	id     ?string
	id_bin []u8
	title  ?string
mut:
	translations ?[]ProductOptionTranslationRequestHygienised
	values       ?[]ProductOptionValueUpdateRequestHygienised
}

fn (p ProductOptionUpdateRequest) hygienise() !ProductOptionUpdateRequestHygienised {
	mut ph := ProductOptionUpdateRequestHygienised{
		title: p.title
	}

	if translations := p.translations {
		mut ts := []ProductOptionTranslationRequestHygienised{len: translations.len}
		for i := 0; i < translations.len; i++ {
			ts[i] = translations[i].hygienise()!
		}
		ph.translations = ts
	}

	return ph
}

// verifies:
// title is not empty
// All locale_id exist TODO
fn (ph ProductOptionUpdateRequestHygienised) verify() ! {
	if title := ph.title {
		if title == '' {
			return new_internal_error(error_field_empty, 'The product_option lacks a title')
		}
	}

	// if translations := ph.translations {
	// TODO verify locale_id
	// }
}

pub struct ProductVariantMoneyAmountRequest {
pub:
	amount      i32
	region_id   string @[json: 'regionId']
	is_original ?bool  @[json: 'isOriginal']
}

struct VariantMoneyAmountRequestHygienised {
	amount        i32
	region_id     string
	region_id_bin []u8
	is_original   ?bool
}

fn (p ProductVariantMoneyAmountRequest) hygienise() !VariantMoneyAmountRequestHygienised {
	region_id_bin := option_id_string_to_id_bin(p.region_id) or {
		return new_internal_error(error_id_invalid, 'region_id')
	}

	return VariantMoneyAmountRequestHygienised{
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
// ## inventory_item
// See InventoryItemUpdateRequest.
//
// ## option_value_indexes
// Required.
// Array of integers that maps this variant to option values by option position.
// - The array must contain exactly one element per product option.
// - The element index represents the option index, while the element value represents the value index.
// For example, `option_value_indices: [2, 0, 1]` means: option at index `0` uses value index `2`; option at index `1` uses value index `0`; option at index `2` uses value index `1`.
//
// ## metadata
// Raw metadata stored as a string. Use for arbitrary user-defined data.
//
// ## money_amounts
// Array of region money amounts for this variant.
// When provided:
// - For each region, there must be at least one money amount with is_original set to false or omitted (the base price).
// - For each region, there may be at most one money amount with is_original set to true (the original price).
// - If a previously stored original price for a region is not included, that original price will be removed.
struct ProductVariantCreateRequest {
pub:
	title                ?string
	ean                  ?string
	upc                  ?string
	barcode              ?string
	inventory_item       ?InventoryItemCreateRequest         @[json: 'inventoryItem']
	option_value_indexes []i32                               @[json: 'optionValueIndexes']
	metadata             ?string                             @[raw]
	money_amounts        ?[]ProductVariantMoneyAmountRequest @[json: 'moneyAmounts']
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
// ## inventory_item
// See InventoryItemUpdateRequest.
// If omitted, inventory fields are not changed.
//
// ## option_values
// Array of integers that maps this variant to option values by option position.
// If provided, it replaces the variant's existing option value mapping.
// - The array must contain exactly one element per product option.
// - The element index represents the option index, while the element value represents the value index.
// - Example: `option_values: [2, 0, 1]` → option index 0 uses value index 2; option index 1 uses value index 0; option index 2 uses value index 1.
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
	id             ?string
	title          ?string
	ean            ?string
	upc            ?string
	barcode        ?string
	inventory_item ?InventoryItemUpdateRequest         @[json: 'inventoryItem']
	option_values  ?[]i32                              @[json: 'optionValues']
	metadata       ?string                             @[raw]
	money_amounts  ?[]ProductVariantMoneyAmountRequest @[json: 'moneyAmounts']
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
// ## money_amounts
// Optional array of region money amounts for this variant.
// When provided:
// - For each region, there must be at least one money amount with is_original set to false or omitted. This is the base_price of the variant.
// - For each region, there may be at most one money amount with is_original set to true. This is the original_price.
// When omitted:
// All region money amounts will be initialized to a default value of 0.
pub struct VariantCreateRequest {
pub:
	title            ?string
	ean              ?string
	upc              ?string
	barcode          ?string
	inventory_item   ?InventoryItemCreateRequest         @[json: 'inventoryItem']
	option_value_ids []string                            @[json: 'optionValueIds']
	metadata         ?string                             @[raw]
	money_amounts    ?[]ProductVariantMoneyAmountRequest @[json: 'moneyAmounts']
}

struct VariantCreateRequestHygienised {
	title                ?string
	ean                  ?string
	upc                  ?string
	barcode              ?string
	option_value_ids     []string
	option_value_ids_bin [][]u8
	metadata             ?string
	money_amounts        ?[]VariantMoneyAmountRequestHygienised
mut:
	inventory_item ?InventoryItemCreateRequestHygienised
}

fn (p VariantCreateRequest) hygienise() !VariantCreateRequestHygienised {
	if p.option_value_ids.len == 0 {
		return new_internal_error(error_field_empty, 'option_value_ids cannot be an empty array')
	}

	mut option_value_ids_bin := [][]u8{len: p.option_value_ids.len}
	for i := 0; i < p.option_value_ids.len; i++ {
		id := p.option_value_ids[i]
		id_bin := id_string_to_bin(id) or {
			return new_internal_error(error_id_invalid, 'option_value_ids')
		}
		option_value_ids_bin[i] = id_bin
	}

	mut money_amounts := []VariantMoneyAmountRequestHygienised{}
	if mas := p.money_amounts {
		if mas.len == 0 {
			new_internal_error(error_field_empty, 'money_amounts cannot be an empty array')
		}

		money_amounts = []VariantMoneyAmountRequestHygienised{len: mas.len}
		for i := 0; i < mas.len; i++ {
			money_amounts[i] = mas[i].hygienise()!
		}
	}

	mut ph := VariantCreateRequestHygienised{
		title:                p.title
		ean:                  p.ean
		upc:                  p.upc
		barcode:              p.barcode
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
// ## money_amounts
// Optional array of region money amounts for this variant.
// When provided:
// - For each region, there must be at least one money amount with is_original set to false or omitted (the base price).
// - For each region, there may be at most one money amount with is_original set to true (the original price).
// - If a previously stored original price for a region is not included, that original price will be removed.
// When omitted:
//  money_amounts are not changed.
pub struct VariantUpdateRequest {
pub:
	title            ?string
	ean              ?string
	upc              ?string
	barcode          ?string
	inventory_item   ?InventoryItemUpdateRequest         @[json: 'inventoryItem']
	option_value_ids ?[]string                           @[json: 'optionValueIds']
	metadata         ?string                             @[raw]
	money_amounts    ?[]ProductVariantMoneyAmountRequest @[json: 'moneyAmounts']
}

struct VariantUpdateRequestHygienised {
	title                ?string
	ean                  ?string
	upc                  ?string
	barcode              ?string
	inventory_item       ?InventoryItemUpdateRequest
	option_value_ids     ?[]string
	option_value_ids_bin [][]u8
	metadata             ?string
mut:
	money_amounts ?[]VariantMoneyAmountRequestHygienised
}

fn (p VariantUpdateRequest) hygienise() !VariantUpdateRequestHygienised {
	option_value_ids_bin := option_array_id_string_to_array_id_bin(p.option_value_ids) or {
		return new_internal_error(error_id_invalid, 'option_value_ids')
	}

	mut ph := VariantUpdateRequestHygienised{
		title:                p.title
		ean:                  p.ean
		upc:                  p.upc
		barcode:              p.barcode
		inventory_item:       p.inventory_item
		option_value_ids:     p.option_value_ids
		option_value_ids_bin: option_value_ids_bin
		metadata:             p.metadata
	}

	if money_amounts := p.money_amounts {
		mut h := []VariantMoneyAmountRequestHygienised{len: money_amounts.len}
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

pub struct SEOTranslationRequest {
pub:
	locale_id   string @[json: 'localeId']
	title       ?string
	description ?string
}

struct SEOTranslationRequestHygienised {
	locale_id     string
	locale_id_bin []u8
	title         ?string
	description   ?string
}

fn (p SEOTranslationRequest) hygienise() !SEOTranslationRequestHygienised {
	locale_id_bin := id_string_to_bin(p.locale_id) or {
		return new_internal_error(error_id_invalid, 'locale_id')
	}

	return SEOTranslationRequestHygienised{
		locale_id:     p.locale_id
		locale_id_bin: locale_id_bin
		title:         p.title
		description:   p.description
	}
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
// Localized versions of SEO fields. To remove all translations, submit an empty array.
pub struct SEORequest {
pub:
	title        ?string
	description  ?string
	translations ?[]SEOTranslationRequest
}

struct SEORequestHygienised {
	title       ?string
	description ?string
mut:
	translations ?[]SEOTranslationRequestHygienised
}

fn (p SEORequest) hygienise() !SEORequestHygienised {
	if p.title == none && p.description == none && p.translations == none {
		return new_internal_error(error_empty_object, 'SEORequest')
	}

	mut r := SEORequestHygienised{
		title:       p.title
		description: p.description
	}

	if translations := p.translations {
		mut hygienised := []SEOTranslationRequestHygienised{len: translations.len}
		for i := 0; i < translations.len; i++ {
			translation := translations[i]
			hygienised[i] = translation.hygienise()!
		}
		r.translations = hygienised
	}

	return r
}

pub struct CategoryCreateRequest {
pub:
	name               string
	description        ?string
	handle             ?string
	is_internal        ?bool   @[json: 'isInternal']
	is_active          ?bool   @[json: 'isActive']
	parent_category_id ?string @[json: 'parentCategoryId']
	metadata           ?string @[raw]
	translations       ?[]CategoryTranslationRequest
	seo                ?SEORequest
}

struct CategoryCreateRequestHygienised {
	name                   string
	description            ?string
	handle                 ?string
	is_internal            ?bool
	is_active              ?bool
	parent_category_id     ?string
	parent_category_id_bin []u8
	metadata               ?string
mut:
	seo          ?SEORequestHygienised
	translations ?[]CategoryTranslationRequestHygienised
}

fn (p CategoryCreateRequest) hygienise() !CategoryCreateRequestHygienised {
	mut parent_category_id_bin := []u8{}
	if parent_category_id := p.parent_category_id {
		parent_category_id_bin = id_string_to_bin(parent_category_id) or {
			return new_internal_error(error_id_invalid, 'parent_category_id')
		}
	}

	mut ph := CategoryCreateRequestHygienised{
		name:                   p.name
		description:            p.description
		handle:                 p.handle
		is_internal:            p.is_internal
		is_active:              p.is_active
		parent_category_id:     p.parent_category_id
		parent_category_id_bin: parent_category_id_bin
		metadata:               p.metadata
	}

	if translations := p.translations {
		mut ts := []CategoryTranslationRequestHygienised{len: translations.len}
		for i := 0; i < translations.len; i++ {
			translation := translations[i]
			locale_id_bin := id_string_to_bin(translation.locale_id) or {
				return new_internal_error(error_id_invalid, 'locale_id')
			}
			ts[i] = CategoryTranslationRequestHygienised{
				locale_id:     translation.locale_id
				locale_id_bin: locale_id_bin
				name:          translation.name
				description:   translation.description
			}
		}
		ph.translations = ts
	}

	if seo := p.seo {
		ph.seo = seo.hygienise()!
	}

	return ph
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
// Localized versions of category fields. To remove all translations, submit an empty array.
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
	translations       ?[]CategoryTranslationRequest
	seo                ?SEORequest
}

struct CategoryUpdateRequestHygienised {
	name                   ?string
	description            ?string
	handle                 ?string
	is_internal            ?bool
	is_active              ?bool
	parent_category_id     ?string
	parent_category_id_bin []u8
	metadata               ?string
mut:
	seo          ?SEORequestHygienised
	translations ?[]CategoryTranslationRequestHygienised
}

fn (p CategoryUpdateRequest) hygienise() !CategoryUpdateRequestHygienised {
	if p.handle == none && p.is_internal == none && p.is_active == none
		&& p.parent_category_id == none && p.metadata == none && p.translations == none {
		return new_internal_error(error_empty_object, 'CategoryUpdateRequest')
	}

	mut parent_category_id_bin := []u8{}
	if parent_category_id := p.parent_category_id {
		parent_category_id_bin = id_string_to_bin(parent_category_id) or {
			return new_internal_error(error_id_invalid, 'parent_category_id')
		}
	}

	mut ph := CategoryUpdateRequestHygienised{
		name:                   p.name
		description:            p.description
		handle:                 p.handle
		is_internal:            p.is_internal
		is_active:              p.is_active
		parent_category_id:     p.parent_category_id
		parent_category_id_bin: parent_category_id_bin
		metadata:               p.metadata
	}

	if translations := p.translations {
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

	if seo := p.seo {
		ph.seo = seo.hygienise()!
	}

	return ph
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
// ## type_id
// Product type identifier.
//
// ## discountable
// Whether the product is eligible for discounts.
//
// ## metadata
// Raw metadata stored as a string.
//
// ## tag_ids
// Tags to associate with the product.
//
// ## sales_channel_ids
// Sales channels where the product will be available.
//
// ## category_ids
// Categories the product belongs to.
//
// ## translations
// Localized versions of product fields.
//
// ## seo
// SEO metadata.
//
// ## options
// Product options (e.g. size, color).
//
// ## variants
// The array order is preserved.
// If variants is provided with one element and options is omitted, the default variant will be created according to the data of the provided element.
// If variants is omitted and options is omitted, one default variant will be created using the default option and the default value.
// If variants is omitted but options is provided, one default variant will be created utilizing the first option and its first value.
//
// ## thumbnail
// Index of the thumbnail image within the `images` array.
// If omitted, the first image in `images` is used.
// If `images` is empty or omitted, the product is created without a thumbnail.
//
// ## images
// Images to associate with the product.
// Images preserve sorting order.
pub struct ProductCreateRequest {
pub:
	title             string
	subtitle          ?string
	description       ?string
	handle            ?string
	is_giftcard       ?bool @[json: 'isGiftcard']
	status            ?string
	type_id           ?string @[json: 'typeId']
	discountable      ?bool
	metadata          ?string   @[raw]
	tag_ids           ?[]string @[json: 'tagIds']
	sales_channel_ids ?[]string @[json: 'salesChannelIds']
	category_ids      ?[]string @[json: 'categoryIds']
	translations      ?[]ProductTranslationRequest
	seo               ?SEORequest
	options           ?[]ProductOptionCreateRequest
	variants          ?[]ProductVariantCreateRequest
	thumbnail         ?i32
	images            ?[]ImageCreateRequest
}

// TODO derive handle from title using slugify
// TODO append id to handle if handle already exists in database
struct ProductCreateRequestHygienised {
	title                 string
	subtitle              ?string
	description           ?string
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
	thumbnail             ?i32
mut:
	seo          ?SEORequestHygienised
	options      ?[]ProductOptionCreateRequestHygienised
	translations ?[]ProductTranslationRequestHygienised
	images       ?[]ImageCreateRequestHygienised
}

fn (p ProductCreateRequest) hygienise() !ProductCreateRequestHygienised {
	if p.title == '' {
		return new_internal_error(error_field_empty, 'title')
	}

	if utf8_str_visible_length(p.title) > max_length_product_title {
		return new_internal_error(error_field_too_long, 'title')
	}

	if subtitle := p.subtitle {
		if utf8_str_visible_length(subtitle) > max_length_product_subtitle {
			return new_internal_error(error_field_too_long, 'subtitle')
		}
	}

	if thumbnail := p.thumbnail {
		if thumbnail < 0 {
			return new_internal_error('thumbnail invalid', 'negative value')
		}

		if images := p.images {
			if !(thumbnail < images.len) {
				return new_internal_error('thumbnail invalid', 'index out of range')
			}
		} else {
			return new_internal_error('thumbnail invalid', 'images array not provided')
		}
	}

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

	mut ph := ProductCreateRequestHygienised{
		title:                 p.title
		subtitle:              p.subtitle
		description:           p.description
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
			h[i] = translations[i].hygienise()!
		}
		ph.translations = h
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
// ## type_id
// Product type identifier.
//
// ## discountable
// Whether the product is eligible for discounts.
//
// ## metadata
// Raw metadata stored as a string.
//
// ## tag_ids
// Tags to associate with the product. To remove the product from all tags, submit an empty array.
//
// ## sales_channel_ids
// Sales channels where the product will be available.
//
// ## category_ids
// Categories the product belongs to. To remove the product from all categories, submit an empty array.
//
// ## translations
// Localized versions of product fields. To remove all translations, submit an empty array.
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
	type_id           ?string @[json: 'typeId']
	discountable      ?bool
	metadata          ?string   @[raw]
	tag_ids           ?[]string @[json: 'tagIds']
	sales_channel_ids ?[]string @[json: 'salesChannelIds']
	category_ids      ?[]string @[json: 'categoryIds']
	translations      ?[]ProductTranslationRequest
	thumbnail         ?i32
	images            ?[]ImageUpdateRequest
	seo               ?SEORequest
	options           ?[]ProductOptionUpdateRequest
	variants          ?[]ProductVariantUpdateRequest
}

// TODO verify title != ''
// TODO handle '' subtitle and description
// TODO verify title.len <= 63
// TODO verify subtitle.len <= 191
// TODO handle '' handle
struct ProductUpdateRequestHygienised {
	title                 ?string
	subtitle              ?string
	description           ?string
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
	thumbnail             ?i32
mut:
	translations ?[]ProductTranslationRequestHygienised
	images       ?[]ImageUpdateRequestHygienised
	seo          ?SEORequestHygienised
}

fn (p ProductUpdateRequest) hygienise() !ProductUpdateRequestHygienised {
	if title := p.title {
		if title == '' {
			return new_internal_error(error_field_empty, 'title')
		}

		if utf8_str_visible_length(title) > max_length_product_title {
			return new_internal_error(error_field_too_long, 'title')
		}
	}

	if subtitle := p.subtitle {
		if utf8_str_visible_length(subtitle) > max_length_product_subtitle {
			return new_internal_error(error_field_too_long, 'subtitle')
		}
	}

	if thumbnail := p.thumbnail {
		if thumbnail < 0 {
			return new_internal_error('thumbnail invalid', 'negative value')
		}

		if images := p.images {
			if !(thumbnail < images.len) {
				return new_internal_error('thumbnail invalid', 'index out of range')
			}
		} else {
			return new_internal_error('thumbnail invalid', 'images array not provided')
		}
	}

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

	mut ph := ProductUpdateRequestHygienised{
		title:                 p.title
		subtitle:              p.subtitle
		description:           p.description
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
		thumbnail:             p.thumbnail
	}

	if translations := p.translations {
		mut h := []ProductTranslationRequestHygienised{len: translations.len}
		for i := 0; i < translations.len; i++ {
			h[i] = translations[i].hygienise()!
		}
		ph.translations = h
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

	return ph
}
