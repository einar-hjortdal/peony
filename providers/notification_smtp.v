module providers

import net.smtp

pub struct SMTPClient {
	name string
mut:
	client &smtp.Client
}

pub fn new_notification_provider_smtp(name string, config smtp.Config) !&SMTPClient {
	return &SMTPClient{
		name:   name
		client: smtp.new_client(config)!
	}
}

pub fn (c SMTPClient) name() string {
	return c.name
}

pub fn (c SMTPClient) send(notification NotificationData) NotificationResult {
	c.client.send(smtp.Mail{}) or { return NotificationResult{
		error: err
	} }
	return NotificationResult{}
}
