module peony

import net.http
import veb
import json

const error_database_data_malformed = 'Data retrieved from database is malformed'
const error_field_empty = 'Field cannot be empty'
const error_field_too_long = 'Field too long'
const error_empty_object = 'Received all empty fields'
const error_header_invalid = 'Invalid header'
const error_header_missing = 'Missing header'
const error_id_generation = 'Failed to generate id'
const error_id_invalid = 'Invalid id'
const error_order_direction_invalid = 'Invalid order direction'
const error_transaction_commit = 'Failed to start transaction'
const error_transaction_rollback = 'Failed to rollback transaction'
const error_transaction_start = 'Failed to start transaction'

const details_order_direction_invalid = 'order direction must either be ${order_direction_asc} or ${order_direction_desc}'

fn success(mut ctx Context) veb.Result {
	return ctx.json(PeonySuccess{
		success: true
	})
}

fn (mut ctx Context) handle_peony_error(err PeonyError) veb.Result {
	ctx.res.set_status(err.status_code)
	return ctx.json(json.encode(PeonyErrorResponse{
		message: err.message
		details: err.details
	}))
}

fn (mut ctx Context) handle_error(err IError) veb.Result {
	if err is PeonyError {
		return ctx.handle_peony_error(err)
	}
	perr := new_error_internal('Unhandled error', err.msg())
	return ctx.handle_peony_error(perr)
}

// TODO remove in favor of handle_error
fn (mut ctx Context) handle_unhandled_error(function_name string, error_message string) veb.Result {
	ctx.res.set_status(http.Status.internal_server_error)
	return ctx.json(json.encode(PeonyErrorResponse{
		message: 'Unhandled error at ${function_name}'
		details: error_message
	}))
}

// TODO deprecate
fn new_peony_error_response(message string, details string) PeonyErrorResponse {
	return PeonyErrorResponse{
		message: message
		details: details
	}
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
