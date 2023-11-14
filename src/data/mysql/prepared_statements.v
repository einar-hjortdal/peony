module mysql

import arrays
import db.mysql as v_mysql
import strings

interface Param {}

struct Stmt {
	conn        &v_mysql.DB
	name        string // luuid v2
	param_count int
	allocated   bool
}

// prep_n_exec prepares and executes a statement with the given parameters. After the execution, the
// statement is deallocated.
// It returns the `v_mysql.Result` of the prepared statement execution, or any error that occurs instead.
// This function is convenient to execute prepared statements that are meant to be executed once only.
pub fn prep_n_exec(mut mysql_conn v_mysql.DB, name string, statement string, params ...Param) !v_mysql.Result {
	prep(mut mysql_conn, name, statement)!
	res := exec(mut mysql_conn, name, ...params) or {
		deallocate(mut mysql_conn, name)
		return err
	}

	if params.len > 0 {
		cleanup(mut mysql_conn, name, params.len)
	}

	return res
}

// prep prepares a statement on the MySQL server.
// TODO return a struct
pub fn prep(mut mysql_conn v_mysql.DB, name string, statement string) ! {
	escaped_query := escape_string(statement)
	prepared := "PREPARE ${name} FROM '${escaped_query}'"
	_ := mysql_conn.real_query(prepared)!
}

// exec executes a prepared statement with the given parameters.
// After the execution, the statement is not deallocated and can be executed again.
// The statement is also not deallocated in case of error.
// TODO method of the struct returned by prep
pub fn exec(mut mysql_conn v_mysql.DB, name string, params ...Param) !v_mysql.Result {
	if params.len == 0 {
		res := mysql_conn.real_query('EXECUTE "${name}"') or { return err }
		return res
	}

	mut vars := []string{}

	for i := 0; i < params.len; i += 1 {
		param := params[i]
		match param {
			string {
				// string literals must be wrapped in single quotes
				escaped_string := mysql_conn.escape_string(param)
				_ := mysql_conn.real_query("SET @v${i} = '${escaped_string}'") or {
					null_vars(mut mysql_conn, i)
					return err
				}
			}
			int {
				_ := mysql_conn.real_query('SET @v${i} = ${param}') or {
					null_vars(mut mysql_conn, i)
					return err
				}
			}
			bool { // https://github.com/vlang/v/issues/19834
				// In MySQL boolean values are stored as bit(1): 0x01 is true and 0x00 is false.
				if param == true {
					_ := mysql_conn.real_query('SET @v${i} = 0x01') or {
						null_vars(mut mysql_conn, i)
						return err
					}
				} else {
					_ := mysql_conn.real_query('SET @v${i} = 0x00') or {
						null_vars(mut mysql_conn, i)
						return err
					}
				}
			}
			else {
				null_vars(mut mysql_conn, i)
				return error('Param type not supported: ${param}')
			}
		}
		vars = arrays.concat(vars, '@v${i}')
	}

	res := mysql_conn.real_query('EXECUTE "${name}" using ${vars.join(', ')}') or {
		null_vars(mut mysql_conn, params.len)
		return err
	}
	null_vars(mut mysql_conn, params.len)
	return res
}

fn cleanup(mut mysql_conn v_mysql.DB, name string, index int) {
	null_vars(mut mysql_conn, index)
	deallocate(mut mysql_conn, name)
}

fn null_vars(mut mysql_conn v_mysql.DB, index int) {
	for i := 0; i < index; i += 1 {
		mysql_conn.real_query('SET @v${i} = NULL') or {}
	}
}

pub fn deallocate(mut mysql_conn v_mysql.DB, name string) {
	mysql_conn.real_query('DEALLOCATE PREPARE "${name}"') or {}
}

// escape_single_quotes returns a string that escapes `'` with `''` according to the ANSI SQL standard.
fn escape_single_quotes(query string) string {
	return query.replace("'", "''")
}

// columns returns a string of columns, double-quoted and separated by commas.
// DEPRECATED
pub fn columns(columns []string) string {
	if columns.len == 0 {
		return ''
	}
	mut column_string := ''
	for column in columns {
		column_string += '"${column}", '
	}
	return column_string.trim_string_right(', ')
}

// qualified_columns returns a string of columns, double-quoted and separated by commas, that also include
// explicit column qualification.
// DEPRECATED
pub fn qualified_columns(columns []string, table string) string {
	if columns.len == 0 {
		return ''
	}
	mut column_string := ''
	for column in columns {
		column_string += '"${table}"."${column}", '
	}
	return column_string.trim_string_right(', ')
}

// question_marks returns a string of question marks, separated by commas, for each parameter.
// `parameters` is usually equal to `columns` in insert statements.
// DEPRECATED
pub fn question_marks(parameters []string) string {
	if parameters.len == 0 {
		return ''
	}

	mut question_marks := ''
	for _ in parameters {
		question_marks += '?, '
	}
	return question_marks.trim_string_right(', ')
}

// escape_string escapes special characters in a string for use in an SQL statement.
// This function is not compatible with NO_BACKSLASH_ESCAPES mode.
pub fn escape_string(s string) string {
	mut res := strings.new_builder(s.len * 2)
	for ch in s {
		match ch {
			0 { // NUL
				res.write_u8(r'\'[0])
				res.write_u8(ch)
			}
			10 { // LF (\n)
				res.write_u8(r'\'[0])
				res.write_u8(ch)
			}
			13 { // CR (\r)
				res.write_u8(r'\'[0])
				res.write_u8(ch)
			}
			26 { // SUB (Z)
				res.write_u8(r'\'[0])
				res.write_u8(ch)
			}
			39 { // '
				res.write_u8(r'\'[0])
				res.write_u8(ch)
			}
			34 { // "
				res.write_u8(r'\'[0])
				res.write_u8(ch)
			}
			92 { // \
				res.write_u8(r'\'[0])
				res.write_u8(ch)
			}
			else {
				res.write_u8(ch)
			}
		}
	}
	return res.bytestr()
}
