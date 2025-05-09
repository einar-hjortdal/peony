module main

import arrays

const order_asc = 'ASC'
const order_desc = 'DESC'

fn get_columns(columns []string) string {
	return columns.join(', ')
}

fn get_placeholders(a []string) string {
	mut res := []string{}
	for i := 0; i < a.len; i++ {
		res = arrays.concat(res, '?')
	}
	return res.join(', ')
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
