module peony

import json
import net.http
import veb
import einar_hjortdal.luuid
import einar_hjortdal.firebird
import internal.conduit
import internal.errors
import internal.common
import time

pub const lib = 'peony'

const min_fetch = common.min_fetch
const max_fetch = common.max_fetch

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
pub const max_length_region_name = 63
pub const max_length_handle = 63
pub const max_length_sku = 63
pub const max_length_country = 2
pub const max_length_hs_code = 63
pub const max_length_mid_code = 15
pub const max_length_material = 191
pub const max_length_api_key_name = 63

pub const default_thumbnail = 0

const error_database_data_malformed = conduit.error_database_data_malformed
const error_api_key_invalid = 'Invalid API Key'
const error_empty_object = 'Received all empty fields'
const error_field_invalid = 'Invalid field'
const error_field_empty = 'Field cannot be empty'
const error_field_explicit_empty = 'Field explicitly empty'
const error_field_too_long = 'Field too long'
const error_header_invalid = 'Invalid header'
const error_header_missing = 'Missing header'
const error_id_generation = 'Failed to generate ID'
const error_id_invalid = errors.msg_id_invalid
const error_order_direction_invalid = 'Invalid order direction'
const error_reference_invalid = 'Field references invalid object'
const error_transaction_commit = 'Failed to start transaction'
const error_transaction_rollback = 'Failed to rollback transaction'
const error_transaction_start = 'Failed to start transaction'

const error_handle_fallback_too_long = 'The provided handle already exists. The default fallback is to add the product id to the provided duplicate handle, but this results in the handle being too long. Please provide a unique handle for this product.'

const details_order_direction_invalid = 'order must either be ${order_asc} or ${order_desc}'

const transaction_attempts = 3
const transaction_retry_backoff = 8 * time.millisecond

const offset_default = common.offset_default
const order_asc = common.order_asc
const order_desc = common.order_desc
const order_default = common.order_default

const role_admin = common.role_admin
const role_member = common.role_member
const role_developer = common.role_developer
const role_author = common.role_author
const role_contributor = common.role_contributor

const roles = [
	role_admin,
	role_member,
	role_developer,
	role_author,
	role_contributor,
]

fn role_is_valid(role string) ! {
	match role {
		role_admin, role_member, role_developer, role_author, role_contributor {}
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
		return errors.internal(error_transaction_start, err.msg())
	}
	return tx
}

struct NilReturn {}

struct ListReturn[T] {
	count i64
	items []T
}

fn (mut app App) attempt_transaction[T](ops fn (mut tx firebird.ClientTransaction) !T,
	finalise fn (mut tx firebird.ClientTransaction) !) !T {
	for i = 0; i < transaction_attempts; i++ {
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
}

fn (mut app App) with_rollback[T](ops fn (mut tx firebird.ClientTransaction) !T) !T {
	return attempt_transaction(ops, fn (mut tx firebird.ClientTransaction) ! {
		tx.rollback() or { return errors.internal(error_transaction_rollback, error.msg()) }
	})
}

fn (mut app App) with_commit[T](ops fn (mut tx firebird.ClientTransaction) !T) !T {
	return attempt_transaction(ops, fn (mut tx firebird.ClientTransaction) ! {
		tx.commit() or { return errors.internal(error_transaction_commit, error.msg()) }
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

fn (mut ctx Context) handle_peony_error(error errors.PeonyError) veb.Result {
	ctx.res.set_status(error.status_code)
	return ctx.json(json.encode(PeonyErrorResponse{
		message: error.message
		details: error.details
	}))
}

fn (mut ctx Context) handle_error(error IError) veb.Result {
	match error {
		PeonyError {
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

fn (ctx Context) get_api_key() !APIKey {
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
	return s == product_status_draft || s == product_status_proposed
		|| s == product_status_published || s == product_status_rejected
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

fn bool_or(b ?bool, default bool) bool {
	if v := b {
		return v
	}
	return default
}

fn parse_order_direction(s string) !string {
	normalized := s.to_upper()
	if normalized == order_asc {
		return order_asc
	}

	if normalized == order_desc {
		return order_desc
	}

	return errors.unprocessable_entity(error_order_direction_invalid,
		details_order_direction_invalid)
}

fn get_header_content_type(mut ctx Context) !string {
	return ctx.get_header(http.CommonHeader.content_type)
}

fn get_fetch_or_default(fetch ?i32) !i32 {
	f := fetch or { return max_fetch }
	if f < min_fetch {
		return errors.unprocessable_entity('Too few objects requested. Minimum ${min_fetch} must be requested',
			'requested ${f}')
	}

	if f > max_fetch {
		return errors.unprocessable_entity('Too many objects requested. Maximum ${max_fetch} can be requested',
			'requested ${f}')
	}

	return f
}

fn get_offset_or_default(offset ?i32) !i32 {
	o := offset or { return offset_default }
	if o < offset_default {
		return errors.unprocessable_entity('Minimum offset is ${offset_default}', 'requested ${o}')
	}
	return o
}

fn get_order_direction_or_default(direction ?string) !string {
	d := direction or { return order_default }
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
