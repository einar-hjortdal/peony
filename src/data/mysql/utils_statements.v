module mysql

import arrays
import db.mysql as v_mysql
import strings
import rand
// first party
// import coachonko.luuid

interface Param {}

struct Stmt {
	name        string // TODO luuid v2b
	param_count int
mut:
	conn      v_mysql.DB
	allocated bool
}

// prep_n_exec prepares and executes a statement with the given parameters. After the execution, the
// statement is deallocated.
// It returns the `v_mysql.Result` of the prepared statement execution, or any error that occurs instead.
// This function is convenient to execute prepared statements that are meant to be executed once only.
pub fn prepare_n_exec(mut mysql_conn v_mysql.DB, statement string, params ...Param) !v_mysql.Result {
	mut stmt := prepare(mut mysql_conn, statement)!
	res := stmt.exec(...params) or {
		stmt.deallocate()
		return err
	}

	if params.len > 0 {
		stmt.cleanup(params.len)
	}

	return res
}

// Deprecated: use prepare_n_exc
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

// Deprecated: use prepare
pub fn prep(mut mysql_conn v_mysql.DB, name string, statement string) ! {
	escaped_query := escape_string(statement)
	prepared := "PREPARE ${name} FROM '${escaped_query}'"
	_ := mysql_conn.real_query(prepared)!
}

// prepare prepares a statement on the MySQL server.
// TODO replace prep with this function
pub fn prepare(mut mysql_conn v_mysql.DB, statement string) !&Stmt {
	stmt_name := rand.uuid_v4() // TODO replace with luuid_v2b (without generator)
	escaped_query := escape_string(statement)
	prepared := "PREPARE ${stmt_name} FROM '${escaped_query}'"
	mysql_conn.real_query(prepared)!
	return &Stmt{
		name: stmt_name
		conn: mysql_conn
		allocated: true
	}
}

// TODO replace exec with this function
pub fn (mut stmt Stmt) exec(params ...Param) !v_mysql.Result {
	if params.len == 0 {
		res := stmt.conn.real_query('EXECUTE "${stmt.name}"') or { return err }
		return res
	}

	mut vars := []string{}

	for i := 0; i < params.len; i += 1 {
		param := params[i]
		match param {
			string {
				// string literals must be wrapped in single quotes
				escaped_string := escape_string(param)
				stmt.conn.real_query("SET @v${i} = '${escaped_string}'") or {
					stmt.null_vars(i)
					return err
				}
			}
			int {
				stmt.conn.real_query('SET @v${i} = ${param}') or {
					stmt.null_vars(i)
					return err
				}
			}
			bool {
				// In MySQL boolean values are stored as bit(1): 0x01 is true and 0x00 is false.
				if param == true {
					stmt.conn.real_query('SET @v${i} = 0x01') or {
						stmt.null_vars(i)
						return err
					}
				} else {
					stmt.conn.real_query('SET @v${i} = 0x00') or {
						stmt.null_vars(i)
						return err
					}
				}
			}
			else {
				stmt.null_vars(i)
				return error('Param type not supported: ${param}')
			}
		}
		vars = arrays.concat(vars, '@v${i}')
	}

	res := stmt.conn.real_query('EXECUTE "${stmt.name}" using ${vars.join(', ')}') or {
		stmt.null_vars(params.len)
		return err
	}
	stmt.null_vars(params.len)
	return res
}

// Deprecated: use Stmt.exec
// exec executes a prepared statement with the given parameters.
// After the execution, the statement is not deallocated and can be executed again.
// The statement is also not deallocated in case of error.
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

fn (mut stmt Stmt) cleanup(index int) {
	stmt.null_vars(index)
	stmt.deallocate()
}

// Deprecated: use Stmt.cleanup
fn cleanup(mut mysql_conn v_mysql.DB, name string, index int) {
	null_vars(mut mysql_conn, index)
	deallocate(mut mysql_conn, name)
}

fn (mut stmt Stmt) null_vars(index int) {
	for i := 0; i < index; i += 1 {
		stmt.conn.real_query('SET @v${i} = NULL') or {}
	}
}

// Deprecated: use Stmt.null_vars
fn null_vars(mut mysql_conn v_mysql.DB, index int) {
	for i := 0; i < index; i += 1 {
		mysql_conn.real_query('SET @v${i} = NULL') or {}
	}
}

fn (mut stmt Stmt) deallocate() {
	stmt.conn.real_query('DEALLOCATE PREPARE "${stmt.name}"') or {}
}

// Deprecated: use Stmt.deallocate
pub fn deallocate(mut mysql_conn v_mysql.DB, name string) {
	mysql_conn.real_query('DEALLOCATE PREPARE "${name}"') or {}
}

// escape_string escapes special characters in a string for use in an SQL statement.
// This function is not compatible with NO_BACKSLASH_ESCAPES mode.
pub fn escape_string(s string) string {
	mut res := strings.new_builder(s.len * 2)
	for ch in s {
		match ch {
			0 { // NUL (null)
				res.write_u8(92) // \
				res.write_u8(48) // 0
			}
			10 { // LF (line feed)
				res.write_u8(92) // \
				res.write_u8(110) // n
			}
			13 { // CR (carriage return)
				res.write_u8(92) // \
				res.write_u8(114) // r
			}
			26 { // SUB (substitute)
				res.write_u8(92) // \
				res.write_u8(90) // Z
			}
			34,  // "
			39,  // '
			92 { // \
				res.write_u8(92) // \
				res.write_u8(ch)
			}
			else {
				res.write_u8(ch)
			}
		}
	}
	return res.bytestr()
}
