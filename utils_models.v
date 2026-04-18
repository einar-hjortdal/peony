module peony

import einar_hjortdal.firebird

pub const order_asc = 'ASC' // TODO duplicated order_direction_asc
pub const order_desc = 'DESC' // TODO duplicated order_direction_desc
pub const order_default = order_asc // TODO duplicated order_direction_default

fn newln(ln string) string {
	return '\n${ln}'
}

fn appendln(src string, ln string) string {
	return '${src}${newln(ln)}'
}

fn get_cte(cte []string) string {
	if cte.len == 0 {
		return ''
	}
	return newln(cte.join(','))
}

fn get_columns(c []string) string {
	return c.join(', ')
}

fn get_set_columns(c []string) string {
	mut res := []string{len: c.len}
	for i := 0; i < c.len; i++ {
		res[i] = '${c[i]} = ?'
	}
	return res.join(', ')
}

fn get_set_columns_with_updated_at(c []string) string {
	res := 'updated_at = CURRENT_TIMESTAMP'
	if c.len == 0 {
		return res
	}
	return '${res}, ${get_set_columns(c)}'
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

fn get_placeholders[T](a []T) string {
	mut res := []string{len: a.len}
	for i := 0; i < a.len; i++ {
		res[i] = '?'
	}
	return res.join(', ')
}

fn get_conditions(c []string) string {
	if c.len == 0 {
		return ''
	}
	return '\n${c.join(' AND ')}'
}

fn get_where_conditions(c []string) string {
	if c.len == 0 {
		return ''
	}
	return '\nWHERE ${get_conditions(c)}'
}

fn get_merge_source(s []string) string {
	return s.join('\nUNION ALL\n')
}

fn i32_or_max(n i32) i32 {
	if n == 0 {
		return max_i32
	}
	return n
}

fn if_true_then_a_else_b(condition bool, a string, b string) string {
	if condition {
		return a
	}
	return b
}

// TODO delete
fn is_order_desc(s string) bool {
	return s.to_upper() == order_desc
}

// TODO delete
fn get_sorting_order(zs ZeroString) string {
	if zs.is_set && is_order_desc(zs.v) {
		return order_desc
	}
	return order_asc
}

// TODO delete
fn get_offset_amount(zi32 ZeroI32) i32 {
	if zi32.is_set {
		return zi32.v
	}
	return offset_default
}

// TODO delete
fn get_fetch_amount(zi32 ZeroI32) i32 {
	if zi32.is_set {
		return zi32.v
	}
	return max_fetch
}

// TODO open issue?
fn slices_to_values[T](s [][]T) []firebird.Value {
	mut r := []firebird.Value{len: s.len, init: firebird.Value(0)}
	for i := 0; i < s.len; i++ {
		r[i] = s[i]
	}
	return r
}
