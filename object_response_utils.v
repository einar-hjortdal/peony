module peony

import log
import net.http
import veb

const error_database_data_malformed = 'Data retrieved from database is malformed'
const error_empty_field = 'Field cannot be empty'
const error_empty_object = 'Received all empty fields'
const error_header_invalid = 'Invalid header'
const error_header_missing = 'Missing header'
const error_id_generation = 'Failed to generate id'
const error_id_invalid = 'Invalid id'
const error_order_direction_invalid = 'Invalid order direction'
const error_missing_default_translation = 'Default translation is required'
const error_transaction_commit = 'Failed to start transaction'
const error_transaction_rollback = 'Failed to rollback transaction'
const error_transaction_start = 'Failed to start transaction'

const details_order_direction_invalid = 'order direction must either be ${order_direction_asc} or ${order_direction_desc}'

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

// 409 conflict
fn handle_error_409(mut ctx Context, message string, details string) veb.Result {
	return handle_error(mut ctx, http.Status.conflict, message, details)
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

fn handle_suite_error(mut ctx Context, e InternalError) veb.Result {
	return handle_error_500(mut ctx, e.message, e.details)
}

// TODO deprecate
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
	return CurrencyResponse{
		code:           c.code
		decimal_digits: c.decimal_digits.value
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

fn format_money_amount_response(m MoneyAmount) MoneyAmountResponse {
	mut price_list_id := ''
	mut variant_id := ''
	if !m.price_list_id_bin.is_null {
		price_list_id = id_bin_to_string(m.price_list_id_bin.value) or {
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
		amount:        m.amount
		region_id:     m.region_id
		currency_code: m.currency_code
		min_quantity:  m.min_quantity.value
		max_quantity:  m.max_quantity.value
		price_list_id: price_list_id
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
		id:            p.id
		created_at:    p.created_at.Time
		updated_at:    p.updated_at.Time
		deleted_at:    p.deleted_at.value.Time
		handle:        p.handle
		is_active:     p.is_active
		is_internal:   p.is_internal
		category_rank: p.category_rank
		metadata:      p.metadata.value
		name:          p.name.value
		description:   p.description.value
		translations:  tr
	}
}
