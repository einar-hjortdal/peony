module peony

import net.http
import einar_hjortdal.luuid

interface Identifiable {
	id_string() string
	id_bytes() []u8
	has_id() bool
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

fn (id ID) has_id() bool {
	if id.s != '' && id.b.len > 0 {
		return true
	}
	return false
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

fn (mut app App) gen_id() ID {
	return new_id(mut app.luuid_generator)
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

fn new_error_internal(message string, details string) PeonyError {
	return new_peony_error(message, details, http.Status.internal_server_error)
}

fn new_error_bad_request(message string, details string) PeonyError {
	return new_peony_error(message, details, http.Status.bad_request)
}

fn new_error_not_found(message string, details string) PeonyError {
	return new_peony_error(message, details, http.Status.not_found)
}

fn new_error_unauthorized(message string, details string) PeonyError {
	return new_peony_error(message, details, http.Status.unauthorized)
}

fn new_error_login() PeonyError {
	return new_error_unauthorized('Invalid email or password', '')
}

fn new_error_fetch_zero() PeonyError {
	return new_error_bad_request('Requested 0 results', 'fetch cannot be 0')
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
