module mail

// vlib
import os
import net.smtp
// local
import utils

fn new_smtp_client() !&smtp.Client {
	smtp_server := os.getenv('SMTP_SERVER')
	smtp_port := os.getenv('SMTP_PORT').int()
	smtp_username := os.getenv('SMTP_USERNAME')
	smtp_password := os.getenv('SMTP_PASSWORD')
	smtp_from := os.getenv('SMTP_FROM')
	mut smtp_ssl := false
	mut smtp_starttls := false

	smtp_ssl_string := os.getenv('SMTP_SSL')
	if utils.can_parse_bool(smtp_ssl_string) {
		smtp_ssl = utils.parse_bool(smtp_ssl_string)
	}

	smtp_starttls_string := os.getenv('SMTP_START_TLS')
	if utils.can_parse_bool(smtp_starttls_string) {
		smtp_starttls = utils.parse_bool(smtp_starttls_string)
	}

	config := smtp.Client{
		server: smtp_server
		port: smtp_port
		username: smtp_username
		password: smtp_password
		from: smtp_from
		ssl: smtp_ssl
		starttls: smtp_starttls
	}

	return smtp.new_client(config)!
}
