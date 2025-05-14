module main

import arrays
import einar_hjortdal.firebird
import einar_hjortdal.luuid

const order_asc = 'ASC'
const order_desc = 'DESC'

fn appendln(s string, ln string) string {
	return '${s}\n${ln}'
}

fn get_columns(c []string) string {
	return c.join(', ')
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

fn parse_order(order string) string {
	return if_true_then_a_else_b(order.to_upper() == order_asc, order_asc, order_desc)
}

fn (mut app App) start_transaction() !&firebird.Transaction {
	return app.fb.start_transaction(firebird.isolation_level_read_commited)!
}

fn (mut app App) new_id() !(string, []u8) {
	id_string := app.luuid_generator.v1().to_upper()
	id_bin := luuid.to_bytes(id_string)!
	return id_string, id_bin
}

fn id_from_bin(id []u8) !string {
	return luuid.from_bytes(id)!
}

fn id_to_bin(id string) ![]u8 {
	return luuid.to_bytes(id)!
}
