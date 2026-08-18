module record

import einar_hjortdal.firebird
import internal.common

pub struct NotFound {
	Error
}

fn ids_bytes(ids []common.ID) [][]u8 {
	mut res := [][]u8{len: ids.len}
	for i := 0; i < ids.len; i++ {
		res[i] = ids[i].bytes()
	}
	return res
}

fn ids_values(ids []common.ID) []firebird.Value {
	bs := ids_bytes(ids)
	mut r := []firebird.Value{len: 0, cap: bs.len, init: firebird.Null{}}
	for _, id in ids {
		r << id.bytes()
	}
	return r
}

fn get_placeholders[T](a []T) string {
	mut res := []string{len: a.len}
	for i := 0; i < a.len; i++ {
		res[i] = '?'
	}
	return res.join(', ')
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

// TODO use
fn get_count(mut tx firebird.ClientTransaction, query string, params []firebird.Value) !i64 {
	data := tx.execute(query, ...params)!
	rows := data.rows()
	values := rows[0].values() // always returns one row, however TODO check
	count, _ := values[0].get_i64()! // should always return one column, however DODO check
	return count
}
