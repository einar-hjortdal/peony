module providers

import net.smtp

pub const max_length_smtp_client_name = 63

pub struct SMTPClientConfig {
	smtp.Config
pub:
	name     string
	channels []string
}

// TODO manage smtp.Client: reconnect when disconnected, etc. all internal logic
// TODO failures shouldn't stop app execution, but logged
pub struct SMTPClient {
mut:
	client &smtp.Client
}

pub fn new_notification_provider_smtp(config SMTPClientConfig) !&SMTPClient {
	name := config.name.trim_space()

	if utf8_str_visible_length(name) > max_length_smtp_client_name {
		return error('name can be at most ${max_length_smtp_client_name} UTF8 characters long')
	}

	return &SMTPClient{
		client: smtp.new_client(config)!
	}
}

pub fn (mut c SMTPClient) send(notification NotificationData) !NotificationResult {
	c.client.send(smtp.Mail{
		// from        string
		to: notification.to
		// subject     string
		// body_type   smtp.BodyType
		// body        string
		// attachments []smtp.Attachment
		// html        Message
		// text        Message
		// boundary    string
	})!
	return NotificationResult{}
}
