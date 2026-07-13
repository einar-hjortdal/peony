module peony

import json
import net.http
import veb
import time
import log
import einar_hjortdal.luuid
import einar_hjortdal.firebird
import internal.conduit
import internal.errors
import internal.common
import objects

pub const lib = 'peony'

pub const length_currency_code = 3
pub const length_country_code = 2

pub const max_length_first_name = 63
pub const max_length_last_name = 63
pub const max_length_alt = 191
pub const max_length_product_title = 63
pub const max_length_product_subtitle = 191
pub const max_length_option_title = 63
pub const max_length_option_value_name = 63
pub const max_length_variant_title = 63
pub const max_length_ean = 13
pub const max_length_upc = 12
pub const max_length_barcode = 63
pub const max_length_seo_title = 63
pub const max_length_seo_description = 191
pub const max_length_category_name = 63
pub const max_length_category_description = 191
pub const max_length_handle = 63
pub const max_length_sku = 63
pub const max_length_country = 2
pub const max_length_hs_code = 63
pub const max_length_mid_code = 15
pub const max_length_material = 191
pub const max_length_api_key_name = 63

pub const default_thumbnail = 0

const error_api_key_invalid = 'Invalid API Key'

const error_empty_object = 'Received all empty fields'
const error_field_invalid = 'Invalid field'
const error_field_empty = 'Field cannot be empty'
const error_field_explicit_empty = 'Field explicitly empty'
const error_field_too_long = 'Field too long'
const error_header_invalid = 'Invalid header'
const error_header_missing = 'Missing header'
const error_id_generation = 'Failed to generate ID'
const error_order_direction_invalid = 'Invalid order direction'
const error_reference_invalid = 'Field references invalid object'

const error_handle_fallback_too_long = 'The provided handle already exists. The default fallback is to add the product id to the provided duplicate handle, but this results in the handle being too long. Please provide a unique handle for this product.'

const details_order_direction_invalid = 'order must either be ${objects.order_asc} or ${objects.order_desc}'

const transaction_attempts = 3
const transaction_retry_backoff = 8 * time.millisecond

const roles = [
	objects.role_admin,
	objects.role_member,
	objects.role_developer,
	objects.role_author,
	objects.role_contributor,
]

fn role_is_valid(role string) ! {
	match role {
		objects.role_admin, objects.role_member, objects.role_developer, objects.role_author,
		objects.role_contributor {}
		else {
			return new_error_role_invalid()
		}
	}
}

pub type ID = common.ID

fn new_id(mut g luuid.Generator) ID {
	return common.new_id(mut g)
}

fn id_from_string(s string) !ID {
	return common.id_from_string(s)
}

fn (mut app App) start_transaction() !&firebird.ClientTransaction {
	tx := app.firebird.start_transaction(firebird.isolation_level_read_commited) or {
		return errors.internal('Failed to start transaction', err.msg())
	}
	return tx
}

fn (mut app App) attempt_transaction[T](ops fn (mut tx firebird.ClientTransaction) !T,
	finalise fn (mut tx firebird.ClientTransaction) !) !T {
	for i := 0; i < transaction_attempts; i++ {
		mut tx := app.start_transaction() or {
			if i == transaction_attempts - 1 {
				return err
			}

			time.sleep(transaction_retry_backoff)
			continue
		}

		res := ops(mut tx) or {
			tx.rollback() or {}
			if i == transaction_attempts - 1 {
				return err
			}

			time.sleep(transaction_retry_backoff)
			continue
		}

		finalise(mut tx)!
		return res
	}

	return errors.internal('Could not complete operation',
		'Transaction failed ${transaction_attempts} times.')
}

fn (mut app App) with_rollback[T](ops fn (mut tx firebird.ClientTransaction) !T) !T {
	return app.attempt_transaction(ops, fn (mut tx firebird.ClientTransaction) ! {
		tx.rollback() or { return errors.internal('Failed to rollback transaction', err.msg()) }
	})
}

fn (mut app App) with_commit[T](ops fn (mut tx firebird.ClientTransaction) !T) !T {
	return app.attempt_transaction(ops, fn (mut tx firebird.ClientTransaction) ! {
		tx.commit() or { return errors.internal('Failed to commit transaction', err.msg()) }
	})
}

// parse_bool returns true if the string represents a true bool.
// Any of the following are accepted values: 1, t, T, TRUE, true, True
fn parse_bool(s string) bool {
	string_true := ['1', 't', 'T', 'TRUE', 'true', 'True']
	for value in string_true {
		if s == value {
			return true
		}
	}
	return false
}

fn get_none_string(m map[string]string, k string) ?string {
	if k in m {
		return m[k]
	}
	return none
}

fn get_none_array_string(m map[string]string, k string) ?[]string {
	s := get_none_string(m, k) or { return none }
	return s.split(',')
}

fn get_none_i32(m map[string]string, k string) ?i32 {
	s := get_none_string(m, k) or { return none }
	return s.i32()
}

fn get_none_bool(m map[string]string, k string) ?bool {
	s := get_none_string(m, k) or { return none }
	return parse_bool(s)
}

// to parse query strings
fn ids_from_array_string(ids_string []string) ![]ID {
	mut ids := []ID{len: ids_string.len}
	for i := 0; i < ids_string.len; i++ {
		ids[i] = id_from_string(ids_string[i])!
	}
	return ids
}

fn (mut app App) gen_id() ID {
	return common.new_id(mut app.luuid_generator)
}

// removes locale_id if default, otherwise makes sure it is a valid locale
fn (mut app App) get_locale_context(m map[string]string) !LocaleContext {
	p := hygienise_locale_context_query_params(m)!

	locale_id := p.locale_id or { return LocaleContext{} }

	default_locale_id := app.get_default_locale_id()!
	if locale_id.string() == default_locale_id.string() {
		log.debug('locale_id matches default, ignoring')
		return LocaleContext{}
	}

	if _ := app.cache_store_locale_get(locale_id) {
		log.debug('locale_id is valid, locale loaded from cache')
		return LocaleContext{
			locale_id: locale_id
		}
	}

	log.debug('locale not in cache, getting enabled locales from db')
	store := app.with_rollback(fn (mut tx firebird.ClientTransaction) !conduit.Store {
		return conduit.store_get(mut tx)!
	})!

	for i := 0; i < store.locales.len; i++ {
		locale := store.locales[i]
		if locale_id.string() != locale.id.string() {
			continue
		}

		log.debug('locale_id is valid and enabled, cache must have expired')
		app.cache_set_store(store)
		return LocaleContext{
			locale_id: locale_id
		}
	}

	log.debug('locale_id is not valid or not enabled')
	return errors.unprocessable_entity(errors.id_invalid, 'locale_id is not valid or not enabled')
}

fn (mut ctx Context) handle_peony_error(error errors.PeonyError) veb.Result {
	ctx.res.set_status(error.status_code)
	return ctx.json(json.encode(PeonyErrorResponse{
		message: error.message
		details: error.details
	}))
}

fn (mut ctx Context) handle_error(error IError) veb.Result {
	match error {
		errors.PeonyError {
			return ctx.handle_peony_error(error)
		}
		else {
			return ctx.handle_peony_error(errors.internal('Unhandled error', error.msg()))
		}
	}
}

fn (mut ctx Context) middleware_handle_error(error IError) bool {
	match error {
		errors.PeonyError {
			ctx.res.set_status(error.status_code)
			ctx.json(json.encode(PeonyErrorResponse{
				message: error.message
				details: error.details
			}))
		}
		else {
			ctx.res.set_status(http.Status.internal_server_error)
			ctx.json(errors.internal('Unhandled middleware error', error.msg()))
		}
	}

	return false
}

fn (mut ctx Context) handle_ok[T](payload T) veb.Result {
	ctx.res.set_status(http.Status.ok)
	return ctx.json(payload)
}

fn (mut ctx Context) handle_created[T](payload T) veb.Result {
	ctx.res.set_status(http.Status.created)
	return ctx.json(payload)
}

fn (mut ctx Context) handle_deleted() veb.Result {
	ctx.res.set_status(http.Status.ok)
	return ctx.json(DeletedResponse{})
}

fn (ctx Context) get_api_key() !conduit.APIKey {
	api_key := ctx.api_key or {
		return errors.internal('API Key missing from request context', 'ctx.api_key == none')
	}

	return api_key
}

fn unwrap_option_or[T](option_type ?T, default_value T) T {
	if some_value := option_type {
		return some_value
	}
	return default_value
}

fn unwrap_option_or_option[T](option_type ?T, default_option ?T) ?T {
	if some_value := option_type {
		return some_value
	}
	return default_option
}

fn keys[T](m map[string]T) []string {
	r := []string{len: m.len}
	mut i := 0
	for k, _ in m {
		r[i] = k
		i++
	}
}

fn format_field_too_long_details(field_name string, max_utf8_length i32) string {
	return '${field_name} can be at most ${max_utf8_length} UTF8 characters long'
}

fn email_is_valid(e string) ! {
	if e.len > 254 {
		return error('email too long')
	}

	// a@b.cd
	if e.len < 6 {
		return error('email too short')
	}

	// TODO contains @
	// TODO illegal characters
}

fn product_status_is_valid(s string) bool {
	return s == objects.product_status_draft || s == objects.product_status_proposed
		|| s == objects.product_status_published || s == objects.product_status_rejected
}

fn string_value(s ?string) string {
	if v := s {
		return v
	}
	return ''
}

fn i32_value(i ?i32) i32 {
	if v := i {
		return v
	}
	return 0
}

fn parse_order_direction(s string) !string {
	normalized := s.to_upper()
	match normalized {
		objects.order_asc {
			return objects.order_asc
		}
		objects.order_desc {
			return objects.order_desc
		}
		else {
			return errors.unprocessable_entity(error_order_direction_invalid,
				details_order_direction_invalid)
		}
	}
}

fn get_header_content_type(mut ctx Context) ?string {
	return ctx.get_header(http.CommonHeader.content_type)
}

fn get_fetch_or_default(fetch ?i32) !i32 {
	f := fetch or { return objects.max_fetch }
	if f < objects.min_fetch {
		return errors.unprocessable_entity('Too few objects requested. Minimum ${objects.min_fetch} must be requested',
			'requested ${f}')
	}

	if f > objects.max_fetch {
		return errors.unprocessable_entity('Too many objects requested. Maximum ${objects.max_fetch} can be requested',
			'requested ${f}')
	}

	return f
}

fn get_offset_or_default(offset ?i32) !i32 {
	o := offset or { return objects.offset_default }
	if o < objects.offset_default {
		return errors.unprocessable_entity('Minimum offset is ${objects.offset_default}',
			'requested ${o}')
	}
	return o
}

fn get_order_direction_or_default(direction ?string) !string {
	d := direction or { return objects.order_default }
	return parse_order_direction(d)
}

struct LocaleContext {
	locale_id ?ID
}

fn new_error_fetch_zero() errors.PeonyError {
	return errors.bad_request('Requested 0 results', 'fetch cannot be 0')
}

fn new_error_role_invalid() errors.PeonyError {
	return errors.unprocessable_entity(error_field_invalid,
		'role must be one of: ${roles.join(', ')}')
}
