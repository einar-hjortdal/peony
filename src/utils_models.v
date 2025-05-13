module main

import arrays

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
	if c.len == 0 {
		return ''
	}
	return '\nWHERE ${c.join(' AND ')}'
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
