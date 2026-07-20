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

pub struct NotificationResult {
pub:
	error ?IError
	id    ?string
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

// TODO: one notification provider should be able to handle 1 or more channels.
// TODO: each notification channel should only be handled by 0 or 1 NotificationProvider.
// TODO: at some point these providers have to be referenced in the db.
// TODO: keep records of each notification in db.
// name: returns the name of the provider. Must be unique: each name is mapped to an id.
pub interface NotificationProvider {
	name() string
	send(notification NotificationData) !NotificationResult
}
