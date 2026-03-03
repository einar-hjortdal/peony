module peony

import json
import net.http
import veb
import einar_hjortdal.luuid
import einar_hjortdal.firebird

pub const min_fetch = i32(1)
pub const max_fetch = i32(250)
pub const default_offset = i32(0)

pub const order_direction_asc = 'ASC'
pub const order_direction_desc = 'DESC'
pub const order_direction_default = order_direction_asc

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

pub const default_thumbnail = 0

const error_database_data_malformed = 'Data retrieved from database is malformed'
const error_field_empty = 'Field cannot be empty'
const error_field_too_long = 'Field too long'
const error_field_explicit_empty = 'Field explicitly empty'
const error_empty_object = 'Received all empty fields'
const error_header_invalid = 'Invalid header'
const error_header_missing = 'Missing header'
const error_id_generation = 'Failed to generate id'
const error_id_invalid = 'Invalid id'
const error_order_direction_invalid = 'Invalid order direction'
const error_transaction_commit = 'Failed to start transaction'
const error_transaction_rollback = 'Failed to rollback transaction'
const error_transaction_start = 'Failed to start transaction'

const error_handle_fallback_too_long = 'The provided handle already exists. The default default fallback is to add the product id to the provided duplicate handle, but this results in the handle being too long. Please provide a unique handle for this product.'

const details_order_direction_invalid = 'order direction must either be ${order_direction_asc} or ${order_direction_desc}'

fn id_string_to_bin(id_string string) ![]u8 {
	return luuid.to_bytes(id_string)
}

fn id_bin_to_string(id_bin []u8) !string {
	return luuid.from_bytes(id_bin)
}

fn (mut app App) new_id() (string, []u8) {
	id_string := app.luuid_generator.v1().to_upper()
	id_bin := id_string_to_bin(id_string) or { panic(err) } // should never panic
	return id_string, id_bin
}

fn (mut app App) start_transaction() !&firebird.Transaction {
	mut tx := app.firebird.start_transaction(firebird.isolation_level_read_commited) or {
		return new_error_internal(error_transaction_start, err.msg())
	}
	return tx
}

// parse_bool returns true if the string represents a true bool, or false if the string represents a
// false bool.
// Any of the following are accepted values: 1, t, T, TRUE, true, True, 0, f, F, FALSE, false, False
// Always call `can_parse_bool` before `parse_bool` to handle strings that cannot be parsed to bool.
fn parse_bool(s string) bool {
	string_true := ['1', 't', 'T', 'TRUE', 'true', 'True']
	for value in string_true {
		if s == value {
			return true
		}
	}
	return false
}

struct ZeroString {
	v      string
	is_set bool
}

// TODO replace all ZeroT with ?T
// TODO change `v` to `value`
fn zero_string(m map[string]string, k string) ZeroString {
	if k in m {
		return ZeroString{
			v:      m[k]
			is_set: true
		}
	}
	return ZeroString{}
}

struct ZeroArrayString {
	v      []string
	is_set bool
}

fn zero_array_string(m map[string]string, k string) ZeroArrayString {
	s := zero_string(m, k)
	if s.is_set {
		return ZeroArrayString{
			v:      s.v.split(',')
			is_set: true
		}
	}
	return ZeroArrayString{}
}

struct ZeroI32 {
	v      i32
	is_set bool
}

fn zero_i32(m map[string]string, k string) ZeroI32 {
	s := zero_string(m, k)
	if s.is_set {
		return ZeroI32{
			v:      s.v.i32()
			is_set: true
		}
	}
	return ZeroI32{}
}

struct ZeroBool {
	v      bool
	is_set bool
}

fn zero_bool(m map[string]string, k string) ZeroBool {
	s := zero_string(m, k)
	if s.is_set {
		if s.v == '' {
			return ZeroBool{
				v:      true
				is_set: true
			}
		}

		return ZeroBool{
			v:      parse_bool(s.v)
			is_set: true
		}
	}
	return ZeroBool{}
}

fn hygienise_fetch_amount(zi32 ZeroI32) !i32 {
	if !zi32.is_set {
		return max_fetch
	}

	if zi32.v < 1 {
		return new_error_bad_request('Too few objects requested. Minimum ${min_fetch} must be requested',
			'requested ${zi32.v}')
	}

	if zi32.v > max_fetch {
		return new_error_bad_request('Too many objects requested. Maximum ${max_fetch} can be requested',
			'requested ${zi32.v}')
	}

	return zi32.v
}

// WIP
interface Identifiable {
	id_string() string
	id_bytes() []u8
}

struct ID {
	s string
	b []u8
}

fn new_id(mut g luuid.Generator) ID {
	s := g.v1().to_upper()
	return ID{
		s: s
		b: luuid.to_bytes(s) or { panic(err) } // should never panic
	}
}

fn (id ID) id_string() string {
	return id.s
}

fn (id ID) id_bytes() []u8 {
	return id.b
}

fn id_from_string(s string) !ID {
	return ID{
		s: s
		b: luuid.to_bytes(s)!
	}
}

fn id_from_bytes(b []u8) !ID {
	return ID{
		s: luuid.from_bytes(b)!
		b: b
	}
}

// for Firebird's `BINARY(16)` columns
fn id_from_nullable_bytes(nb firebird.NullArrayU8) !ID {
	if nb.is_null {
		return ID{}
	}
	return id_from_bytes(nb.value)
}

fn (mut app App) gen_id() ID {
	return new_id(mut app.luuid_generator)
}

// WIP
interface Translation {
	locale_id() string
}

interface Translatable {
	translations() ?[]Translation
}

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

fn (mut ctx Context) handle_peony_error(error PeonyError) veb.Result {
	ctx.res.set_status(error.status_code)
	return ctx.json(json.encode(PeonyErrorResponse{
		message: error.message
		details: error.details
	}))
}

fn (mut ctx Context) handle_error(error IError) veb.Result {
	if error is PeonyError {
		return ctx.handle_peony_error(error)
	}
	return ctx.handle_peony_error(new_error_internal('Unhandled error', error.msg()))
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

// TODO create interface Identifiable with .id() method returning the id
// This would allow to merge all these methods into one
// but first need to decide what id type to use
fn make_product_map(p []Product) (map[string]Product, [][]u8) {
	mut m := map[string]Product{}
	mut a := [][]u8{len: p.len}
	for i := 0; i < p.len; i++ {
		id := p[i].id
		id_bin := p[i].id_bin
		m[id] = p[i]
		a[i] = id_bin
	}
	return m, a
}

fn make_product_variant_map(p []ProductVariant) (map[string]ProductVariant, [][]u8) {
	mut m := map[string]ProductVariant{}
	mut a := [][]u8{len: p.len}
	for i := 0; i < p.len; i++ {
		id := p[i].id
		id_bin := p[i].id_bin
		m[id] = p[i]
		a[i] = id_bin
	}
	return m, a
}

fn make_inventory_item_map(p []InventoryItem) (map[string]InventoryItem, [][]u8) {
	mut m := map[string]InventoryItem{}
	mut a := [][]u8{len: p.len}
	for i := 0; i < p.len; i++ {
		id := p[i].id
		id_bin := p[i].id_bin
		m[id] = p[i]
		a[i] = id_bin
	}
	return m, a
}

fn make_category_map(p []Category) (map[string]Category, [][]u8) {
	mut m := map[string]Category{}
	mut a := [][]u8{len: p.len}
	for i := 0; i < p.len; i++ {
		id := p[i].id
		id_bin := p[i].id_bin
		m[id] = p[i]
		a[i] = id_bin
	}
	return m, a
}

fn make_sales_channel_map(p []SalesChannel) (map[string]SalesChannel, [][]u8) {
	mut m := map[string]SalesChannel{}
	mut a := [][]u8{len: p.len}
	for i := 0; i < p.len; i++ {
		id := p[i].id
		id_bin := p[i].id_bin
		m[id] = p[i]
		a[i] = id_bin
	}
	return m, a
}

fn make_product_option_map(p []ProductOption) (map[string]ProductOption, [][]u8) {
	mut m := map[string]ProductOption{}
	mut a := [][]u8{len: p.len}
	for i := 0; i < p.len; i++ {
		id := p[i].id
		id_bin := p[i].id_bin
		m[id] = p[i]
		a[i] = id_bin
	}
	return m, a
}

fn make_product_option_value_map(p []ProductOptionValue) (map[string]ProductOptionValue, [][]u8) {
	mut m := map[string]ProductOptionValue{}
	mut a := [][]u8{len: p.len}
	for i := 0; i < p.len; i++ {
		id := p[i].id
		id_bin := p[i].id_bin
		m[id] = p[i]
		a[i] = id_bin
	}
	return m, a
}

fn get_sales_channel_ids_bin(sales_channels []SalesChannel) [][]u8 {
	mut sales_channel_ids_bin := [][]u8{len: sales_channels.len}
	for i := 0; i < sales_channels.len; i++ {
		sales_channel_ids_bin[i] = sales_channels[i].id_bin
	}
	return sales_channel_ids_bin
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

fn option_id_string_to_id_bin(option_id_string ?string) ![]u8 {
	if id_string := option_id_string {
		return id_string_to_bin(id_string)!
	}
	return []u8{}
}

fn option_array_id_string_to_array_id_bin(option_array_id_string ?[]string) ![][]u8 {
	if array_id_string := option_array_id_string {
		mut array_id_bin := [][]u8{len: array_id_string.len}
		for i := 0; i < array_id_string.len; i++ {
			array_id_bin[i] = id_string_to_bin(array_id_string[i])!
		}
		return array_id_bin
	}
	return [][]u8{}
}

fn zero_id_string_to_id_bin(zero_id_string ZeroString) ![]u8 {
	if zero_id_string.is_set {
		return id_string_to_bin(zero_id_string.v)!
	}
	return []u8{}
}

fn zero_array_id_string_to_array_id_bin(zero_array_id_string ZeroArrayString) ![][]u8 {
	if zero_array_id_string.is_set {
		mut array_id_bin := [][]u8{len: zero_array_id_string.v.len}
		for i := 0; i < zero_array_id_string.v.len; i++ {
			array_id_bin[i] = id_string_to_bin(zero_array_id_string.v[i])!
		}
		return array_id_bin
	}
	return [][]u8{}
}

fn parse_order_direction(s string) !string {
	normalized := s.to_upper()
	if normalized == order_direction_asc {
		return order_direction_asc
	}

	if normalized == order_desc {
		return order_direction_desc
	}

	return error(error_order_direction_invalid)
}

fn get_order_direction(zs ZeroString) !string {
	if zs.is_set {
		return parse_order_direction(zs.v)
	}
	return ''
}

fn get_header_content_type(mut ctx Context) !string {
	return ctx.get_header(http.CommonHeader.content_type)
}

fn verify_money_amounts(money_amounts []VariantMoneyAmountRequestHygienised, existing_regions []Region) ! {
	mut region_id_map := map[string]bool{}
	for i := 0; i < existing_regions.len; i++ {
		region_id := existing_regions[i].id
		region_id_map[region_id] = true
	}

	mut original_prices_count := 0
	mut base_prices_count := 0
	mut region_map_original_prices := map[string]bool{}
	mut region_map_base_prices := map[string]bool{}
	for i := 0; i < money_amounts.len; i++ {
		money_amount := money_amounts[i]
		region_id := money_amount.region_id
		if region_id !in region_id_map {
			return new_error_bad_request(error_id_invalid, 'There exists no region with id ${region_id}')
		}

		if is_original := money_amount.is_original {
			if is_original {
				if region_id in region_map_original_prices {
					return new_error_bad_request('Multiple original_prices per region',
						'At most one original_price per region is allowed, received 2 for the same region.')
				}

				original_prices_count++
				region_map_original_prices[region_id] = true
				continue
			}
		}

		if region_id in region_map_base_prices {
			return new_error_bad_request('Multiple base_prices per region', 'Exactly one base_price per region required, received 2 for the same region.')
		}

		base_prices_count++
		region_map_base_prices[region_id] = true
	}

	if base_prices_count < existing_regions.len {
		return new_error_bad_request('base_price/region count mismatch', 'Exactly one price per region required, received less prices than the number of existing regions.')
	}
}
