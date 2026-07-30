module providers

import net.http

pub struct BlobFileData {
pub:
	id  string
	url string
}

pub interface BlobProvider {
	create(http.FileData) !BlobFileData
	delete(string) !
}

// WIP

pub struct NotificationResult {
pub:
	id ?string
}

// content: The content of the attachment, encoded as a binary string.
// filename: The filename of the attachment.
// content_type: The MIME type of the attachment.
// disposition: The disposition of the attachment, For example, "inline" or "attachment".
// id: The ID, if the attachment is meant to be referenced within the body of the message.
pub struct NotificationAttachment {
pub:
	content      string
	filename     string
	content_type ?string
	disposition  ?string
	id           ?string
}

pub struct NotificationContent {
pub:
	subject ?string
	text    ?string
	html    ?string
}

// to: the recipient of the notification. email, phone number, or username, depending on the channel.
// from: sender of the notification. email, phone number, or username, depending on the channel.
// attachments:
// channel: channel through which the notification is sent, such as 'email' or 'sms'
// template_name: template name in the provider's system
// provider_data: additional data specific to the provider or channel
// content: content that gets passed to the provider
pub struct NotificationData {
pub:
	to            string
	from          ?string
	attachments   ?[]NotificationAttachment
	channel       string
	template_name string
	data          ?string
	provider_data ?string
	content       ?NotificationContent
}

pub interface NotificationProvider {
mut:
	send(notification NotificationData) !NotificationResult
}

// name:the name of the provider. Must be unique: each name is mapped to an id.
// channels: the name of the channels used by the provider to send notifications. A notification channel can only be served by one provider.
// factory: the factory function used to create a NotificationProvider.
pub struct NotificationProviderConfig {
pub:
	name     string
	channels []string
	factory  fn () !&NotificationProvider @[required]
}
