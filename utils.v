module peony

import json
import net.http
import veb
import einar_hjortdal.luuid
import einar_hjortdal.firebird
import conduit
import conduit.record

pub const lib = 'peony'

pub const min_fetch = conduit.min_fetch
pub const max_fetch = conduit.max_fetch

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
const error_id_invalid = 'Invalid ID'
const error_order_direction_invalid = 'Invalid order direction'
const error_reference_invalid = 'Field references invalid object'
const error_transaction_commit = 'Failed to start transaction'
const error_transaction_rollback = 'Failed to rollback transaction'
const error_transaction_start = 'Failed to start transaction'

const error_handle_fallback_too_long = 'The provided handle already exists. The default fallback is to add the product id to the provided duplicate handle, but this results in the handle being too long. Please provide a unique handle for this product.'

const details_order_direction_invalid = 'order must either be ${order_asc} or ${order_desc}'

pub const offset_default = conduit.offset_default
pub const order_asc = conduit.order_asc
pub const order_desc = conduit.order_desc
pub const order_default = conduit.order_default

pub const role_admin = conduit.role_admin
pub const role_member = conduit.role_member
pub const role_developer = conduit.role_developer
pub const role_author = conduit.role_author
pub const role_contributor = conduit.role_contributor

const roles = [
	role_admin,
	role_member,
	role_developer,
	role_author,
	role_contributor,
]

fn new_id(mut g luuid.Generator) record.ID {
	return conduit.new_id(mut g)
}

fn id_from_string(s string) !record.ID {
	return conduit.id_from_string(s)
}

fn (mut app App) start_transaction() !&firebird.Transaction {
	tx := app.firebird.start_transaction(firebird.isolation_level_read_commited) or {
		return conduit.new_error_internal(error_transaction_start, err.msg())
	}
	return tx
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
fn ids_from_array_string(ids_string []string) ![]record.ID {
	mut ids := []record.ID{len: ids_string.len}
	for i := 0; i < ids_string.len; i++ {
		ids[i] = id_from_string(ids_string[i])!
	}
	return ids
}

fn (mut app App) gen_id() record.ID {
	return conduit.new_id(mut app.luuid_generator)
}

// WIP
interface Translation {
	locale_id() record.ID
}

interface Translatable {
	translations() ?[]Translation
}

fn (mut ctx Context) handle_peony_error(error conduit.PeonyError) veb.Result {
	ctx.res.set_status(error.status_code)
	return ctx.json(json.encode(PeonyErrorResponse{
		message: error.message
		details: error.details
	}))
}

fn (mut ctx Context) handle_error(error IError) veb.Result {
	if error is conduit.PeonyError {
		return ctx.handle_peony_error(error)
	}
	return ctx.handle_peony_error(conduit.new_error_internal('Unhandled error', error.msg()))
}

fn (mut ctx Context) middleware_handle_error(error IError) bool {
	if error is conduit.PeonyError {
		ctx.res.set_status(error.status_code)
		ctx.json(json.encode(PeonyErrorResponse{
			message: error.message
			details: error.details
		}))
	} else {
		ctx.res.set_status(http.Status.internal_server_error)
		ctx.json(conduit.new_error_internal('Unhandled middleware error', error.msg()))
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
		return conduit.new_error_internal('API Key missing from request context',
			'ctx.api_key == none')
	}

	return api_key
}

fn unwrap_option_or[T](option_type ?T, default_value T) T {
	if some_value := option_type {
		return some_value
	}
	return default_value
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

	return conduit.new_error_unprocessable_entity(error_order_direction_invalid,
		details_order_direction_invalid)
}

fn get_header_content_type(mut ctx Context) !string {
	return ctx.get_header(http.CommonHeader.content_type)
}

fn get_fetch_or_default(fetch ?i32) !i32 {
	f := fetch or { return max_fetch }
	if f < min_fetch {
		return conduit.new_error_unprocessable_entity('Too few objects requested. Minimum ${min_fetch} must be requested',
			'requested ${f}')
	}

	if f > max_fetch {
		return conduit.new_error_unprocessable_entity('Too many objects requested. Maximum ${max_fetch} can be requested',
			'requested ${f}')
	}

	return f
}

fn get_offset_or_default(offset ?i32) !i32 {
	o := offset or { return offset_default }
	if o < offset_default {
		return conduit.new_error_unprocessable_entity('Minimum offset is ${offset_default}',
			'requested ${o}')
	}
	return o
}

fn get_order_direction_or_default(direction ?string) !string {
	d := direction or { return order_default }
	return parse_order_direction(d)
}

struct LocaleContext {
	locale_id ?record.ID
}

// TODO delete (use conduit.)

// PeonyError contains the appropriate http status code for the error.
struct PeonyError {
	message     string
	details     string
	status_code http.Status
}

// implement IError
fn (e PeonyError) msg() string {
	return e.message
}

fn (e PeonyError) code() int {
	return i32(e.status_code)
}

fn new_peony_error(message string, details string, code http.Status) PeonyError {
	return PeonyError{
		message:     message
		details:     details
		status_code: code
	}
}

fn new_error_bad_request(message string, details string) PeonyError {
	return new_peony_error(message, details, http.Status.bad_request)
}

fn new_error_unauthorized(message string, details string) PeonyError {
	return new_peony_error(message, details, http.Status.unauthorized)
}

fn new_error_not_found(message string, details string) PeonyError {
	return new_peony_error(message, details, http.Status.not_found)
}

fn new_error_unprocessable_entity(message string, details string) PeonyError {
	return new_peony_error(message, details, http.Status.unprocessable_entity)
}

fn new_error_internal(message string, details string) PeonyError {
	return new_peony_error(message, details, http.Status.internal_server_error)
}

fn new_error_login() PeonyError {
	return new_error_unauthorized('Invalid email or password', '')
}

fn new_error_fetch_zero() PeonyError {
	return new_error_bad_request('Requested 0 results', 'fetch cannot be 0')
}

fn new_error_role_invalid() PeonyError {
	return new_error_unprocessable_entity(error_field_invalid,
		'role must be one of: ${roles.join(', ')}')
}

fn make_identifiable_map[T](identifiables []T) (map[string]T, []record.ID) {
	mut map_res := map[string]T{}
	mut arr_res := []record.ID{len: identifiables.len}
	for i := 0; i < identifiables.len; i++ {
		identifiable := identifiables[i]
		id := identifiable.id()
		map_res[id.string()] = identifiable
		arr_res[i] = id
	}
	return map_res, arr_res
}

