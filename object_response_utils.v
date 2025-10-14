module peony

import log
import net.http
import veb

const error_empty_field = 'Field cannot be empty'
const error_empty_object = 'Received all empty fields'
const error_id_invalid = 'Invalid id'
const error_id_generation = 'Failed to generate id'
const error_header_missing = 'Missing header'
const error_header_invalid = 'Invalid header'
const error_transaction_start = 'Failed to start transaction'
const error_transaction_commit = 'Failed to start transaction'
const error_transaction_rollback = 'Failed to rollback transaction'
const error_database_data_malformed = 'Data retrieved from database is malformed'
const error_missing_default_translation = 'Default translation is required'

fn success(mut ctx Context) veb.Result {
	return ctx.json(PeonySuccess{
		success: true
	})
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

fn handle_error_unhandled(mut ctx Context, message string, fn_name string) veb.Result {
	return handle_error_500(mut ctx, 'Unhandled error at ${fn_name}', message)
}

fn handle_error_login(mut ctx Context) veb.Result {
	return handle_error(mut ctx, http.Status.unauthorized, 'Invalid email or password',
		'No further details')
}

fn handle_fetch_zero(mut ctx Context) veb.Result {
	return handle_error_400(mut ctx, 'Requested 0 results', 'fetch cannot be 0')
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

fn format_locale_response(l Locale) LocaleResponse {
	return LocaleResponse{
		id:   l.id
		code: l.code
	}
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
		default_currency_code:     s.default_currency_code
		default_locale_id:         s.default_locale_id
		default_region_id:         s.default_region_id
		default_stock_location_id: s.default_stock_location_id
		default_sales_channel_id:  s.default_sales_channel_id
		locales:                   locales
		currencies:                currencies
	}
}

fn format_image_translation_response(p ImageTranslation) ImageTranslationResponse {
	return ImageTranslationResponse{
		image_id:  p.image_id
		locale_id: p.locale_id
		alt:       p.alt
	}
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
		image_rank:   p.image_rank
		alt:          p.alt.value
		translations: translations
	}
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

fn format_product_option_value_translation_response(p ProductOptionValueTranslation) ProductOptionValueTranslationResponse {
	return ProductOptionValueTranslationResponse{
		product_option_value_id: p.product_option_value_id
		locale_id:               p.locale_id
		name:                    p.name
	}
}

fn format_product_option_value_response(p ProductOptionValue) ProductOptionValueResponse {
	mut translations := []ProductOptionValueTranslationResponse{len: p.translations.len}
	for i := 0; i < p.translations.len; i++ {
		translations[i] = format_product_option_value_translation_response(p.translations[i])
	}

	return ProductOptionValueResponse{
		id:           p.id
		option_id:    p.option_id
		translations: translations
	}
}

fn format_product_option_translation_response(p ProductOptionTranslation) ProductOptionTranslationResponse {
	return ProductOptionTranslationResponse{
		product_option_id: p.product_option_id
		locale_id:         p.locale_id
		title:             p.title
	}
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

fn format_money_amount_response(m MoneyAmount) MoneyAmountResponse {
	mut price_list_id := ''
	mut region_id := ''
	mut variant_id := ''
	if !m.price_list_id_bin.is_null {
		price_list_id = id_bin_to_string(m.price_list_id_bin.value) or {
			log.error(error_database_data_malformed)
			log.error('money_amount.price_list_id is invalid')
			''
		}
	}

	if !m.region_id_bin.is_null {
		region_id = id_bin_to_string(m.region_id_bin.value) or {
			log.error(error_database_data_malformed)
			log.error('money_amount.price_list_id is invalid')
			''
		}
	}

	if !m.variant_id_bin.is_null {
		variant_id = id_bin_to_string(m.variant_id_bin.value) or {
			log.error(error_database_data_malformed)
			log.error('money_amount.price_list_id is invalid')
			''
		}
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

fn format_inventory_level_response(v InventoryLevel) InventoryLevelResponse {
	return InventoryLevelResponse{
		inventory_item_id: v.inventory_item_id
		stock_location_id: v.stock_location_id
		stocked_quantity:  v.stocked_quantity
		reserved_quantity: v.reserved_quantity
	}
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

fn format_product_variant_response(v ProductVariant, p Prices, product_variants_availability map[string]ProductVariantAvailability) ProductVariantResponse {
	product_variant_availability := product_variants_availability[v.id]

	mut option_values := []ProductOptionValueResponse{len: v.option_values.len}
	for i := 0; i < v.option_values.len; i++ {
		option_values[i] = format_product_option_value_response(v.option_values[i])
	}

	mut money_amounts := []MoneyAmountResponse{len: v.money_amounts.len}
	for i := 0; i < v.money_amounts.len; i++ {
		money_amounts[i] = format_money_amount_response(v.money_amounts[i])
	}

	return ProductVariantResponse{
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
		// TODO variant_image
		inventory_item:     format_inventory_item_response(v.inventory_item) // TODO not for /store/
		option_values:      option_values
		money_amounts:      money_amounts
		prices:             format_prices_response(p) // TODO not for /admin/
		inventory_quantity: product_variant_availability.inventory_quantity
		purchasable:        product_variant_availability.purchasable // TODO not for /admin/
	}
}

fn format_product_variant_response_admin(v ProductVariant, product_variants_availability map[string]ProductVariantAvailability) !ProductVariantResponse {
	return format_product_variant_response(v, Prices{}, product_variants_availability)
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

fn format_product_response_store(p Product, pctx PriceContext, product_variants_availability map[string]ProductVariantAvailability) ProductResponse {
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

	mut variants := []ProductVariantResponse{len: p.variants.len}
	for i := 0; i < p.variants.len; i++ {
		variant := p.variants[i]
		prices := calculate_price(variant, 1, pctx)
		variants[i] = format_product_variant_response(variant, prices, product_variants_availability)
	}

	mut translations := []ProductTranslationResponse{len: p.translations.len}
	for i := 0; i < p.translations.len; i++ {
		translations[i] = format_product_translation_response(p.translations[i])
	}

	mut sales_channels := []SalesChannelResponse{len: p.sales_channels.len}
	for i := 0; i < p.sales_channels.len; i++ {
		sales_channels[i] = format_sales_channel_response(p.sales_channels[i])
	}

	mut categories := []ProductCategoryResponse{len: p.categories.len}
	for i := 0; i < p.categories.len; i++ {
		categories[i] = format_product_category_response(p.categories[i])
	}

	// mut collections := []ProductCollectionResponse{len: p.collections.len}
	// for i := 0; i < p.collections.len; i++ {
	// 	collections[i] = format_product_collection_response(p.collections[i])
	// }

	// TODO tags

	return ProductResponse{
		id:             p.id
		created_at:     p.created_at.Time
		updated_at:     p.updated_at.Time
		deleted_at:     p.deleted_at.value.Time
		handle:         p.handle
		is_giftcard:    p.is_giftcard
		status:         p.status
		thumbnail:      p.thumbnail.value
		type_id:        type_id
		discountable:   p.discountable
		metadata:       p.metadata.value
		title:          p.title.value
		subtitle:       p.subtitle.value
		description:    p.description.value
		images:         images
		options:        options
		variants:       variants
		translations:   translations
		sales_channels: sales_channels
		categories:     categories
		// collections:    collections
		// tags:          tags
	}
}

fn format_product_response_admin(p Product, product_variants_availability map[string]ProductVariantAvailability) ProductResponse {
	return format_product_response_store(p, PriceContext{}, product_variants_availability)
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
		is_active:          p.is_active
		is_internal:        p.is_internal
		parent_category_id: p.parent_category_id
		category_rank:      p.category_rank
		metadata:           p.metadata.value
		name:               p.name.value
		description:        p.description.value
		translations:       tr
	}
}
