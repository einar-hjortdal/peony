module mysql

import db.mysql as v_mysql
import os
import strconv

// new_mysql_conn creates a new MySQL connection using the settings stored in the environment.
pub fn new_mysql_conn() v_mysql.DB {
	// MYSQL_URL provides the host address and the port, divided by a colon
	mysql_url := os.getenv('MYSQL_URL').split(':')
	mut mysql_config := v_mysql.Config{
		host: mysql_url[0]
		port: u32(strconv.parse_uint(mysql_url[1], 10, 32) or { panic(err) })
		username: os.getenv('MYSQL_USER')
		password: os.getenv('MYSQL_PASSWORD')
		dbname: os.getenv('MYSQL_DATABASE')
	}
	mysql_conn := v_mysql.connect(mysql_config) or { panic(err) }
	return mysql_conn
}
