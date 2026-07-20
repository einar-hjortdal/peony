module providers

import net.smtp

pub const max_length_smtp_client_name = 63

pub struct SMTPClientConfig {
	smtp.Config
pub:
	name string
}

pub struct SMTPClient {
	name string
mut:
	client &smtp.Client
}

pub fn new_notification_provider_smtp(config SMTPClientConfig) !&SMTPClient {
	name := config.name.trim_space()
	if name == '' {
		return error('name is required')
	}

	if utf8_str_visible_length(name) > max_length_smtp_client_name {
		return error('name can be at most ${max_length_smtp_client_name} UTF8 characters long')
	}

	return &SMTPClient{
		name:   config.name
		client: smtp.new_client(config)!
	}
}

pub fn (c SMTPClient) name() string {
	return c.name
}

pub fn (c SMTPClient) channels_supported() []string {
	return ['email']
}

pub fn (c SMTPClient) channel() string {
	return 'email'
}

pub fn (c SMTPClient) send(notification NotificationData) !NotificationResult {
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
