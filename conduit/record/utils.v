module record

import einar_hjortdal.luuid
import einar_hjortdal.firebird

pub const offset_default = i32(0)
pub const order_asc = 'ASC'
pub const order_desc = 'DESC'
pub const order_default = order_asc

pub interface Identifiable {
	id() ID
}

pub struct ID {
	s string
	b []u8
}

pub fn new_id(mut g luuid.Generator) ID {
	s := g.v1().to_upper()
	return ID{
		s: s
		b: luuid.to_bytes(s) or { panic(err) } // should never panic
	}
}

// detects if the ID is its zero value
fn (id ID) is_zero() bool {
	return id.s == '' && id.b.len == 0
}

pub fn (id ID) string() string {
	return id.s
}

pub fn (id ID) bytes() []u8 {
	return id.b
}

pub fn id_from_string(s string) !ID {
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

fn get_placeholders[T](a []T) string {
	mut res := []string{len: a.len}
	for i := 0; i < a.len; i++ {
		res[i] = '?'
	}
	return res.join(', ')
}

fn ids_bytes(ids []ID) [][]u8 {
	mut res := [][]u8{len: ids.len}
	for i := 0; i < ids.len; i++ {
		res[i] = ids[i].bytes()
	}
	return res
}

fn ids_values(ids []ID) []firebird.Value {
	bs := ids_bytes(ids)
	mut r := []firebird.Value{len: bs.len, init: []u8{}}
	for i := 0; i < bs.len; i++ {
		r[i] = bs[i]
	}
	return r
}

fn newln(ln string) string {
	return '\n${ln}'
}

fn appendln(src string, ln string) string {
	return '${src}${newln(ln)}'
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

