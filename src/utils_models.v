module main

import arrays
import einar_hjortdal.luuid
import einar_hjortdal.firebird

const order_asc = 'ASC'
const order_desc = 'DESC'
const default_fetch = 15

fn newln(ln string) string {
	return '\n${ln}'
}

fn appendln(src string, ln string) string {
	return '${src}${newln(ln)}'
}

fn get_columns(c []string) string {
	return c.join(', ')
}

fn get_n_placeholders(n i32) string {
	mut res := ''
	if n == 0 {
		return res
	}

	for i := 0; i < n; i++ {
		if i == 0 {
			res += '?'
		} else {
			res += ', ?'
		}
	}
	return res
}

fn get_placeholders(a []string) string {
	mut res := []string{}
	for i := 0; i < a.len; i++ {
		res = arrays.concat(res, '?')
	}
	return res.join(', ')
}

fn get_conditions(c []string) string {
	return c.join(' AND ')
}

fn get_where_conditions(c []string) string {
	if c.len == 0 {
		return ''
	}
	return '\nWHERE ${get_conditions(c)}'
}

fn i32_or_max(n i32) i32 {
	if n == 0 {
		return max_i32
	}
	return n
}

fn string_or_default(s string, d string) string {
	if s != '' {
		return s
	}
	return d
}

fn if_true_then_a_else_b(condition bool, a string, b string) string {
	if condition {
		return a
	}
	return b
}

fn is_order_desc(s string) bool {
	return s.to_upper() == order_desc
}

fn get_sorting_order(zs ZeroString) string {
	if zs.is_set && is_order_desc(zs.v) {
		return order_desc
	}
	return order_asc
}

fn get_fetch_amount(zi32 ZeroI32) i32 {
	if zi32.is_set {
		return zi32.v
	}
	return default_fetch
}

fn (mut app App) start_transaction() !&firebird.Transaction {
	return app.fb.start_transaction(firebird.isolation_level_read_commited)!
}

fn id_string_to_bin(id_string string) ![]u8 {
	return luuid.to_bytes(id_string)
}

fn id_bin_to_string(id_bin []u8) !string {
	return luuid.from_bytes(id_bin)
}

fn new_id(mut g luuid.Generator) !(string, []u8) {
	id_string := g.v1().to_upper()
	id_bin := id_string_to_bin(id_string)!
	return id_string, id_bin
}

fn (mut app App) new_id() !(string, []u8) {
	return new_id(mut app.luuid_generator)
}
