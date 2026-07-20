module providers

import net.http

// WIP

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

// TODO: at application startup, check provider names exist in db. If they don't exist generate id and add an entry.
// TODO: instead of keeping array in app, keep a map? (parse providers struct)
// TODO: Code-driven configuration: no API endpoints to configure which event uses which channel.
//   ask for default channel for:
//     - password reset
//     - customer create/update/delete
//     - shipment create
//     - delivery create
//     - invite create/accept/delete/send
//     - order create/update/cancel/complete
//     - return request/receive
//     - exchange create/receive

// name: returns the name of the provider. Must be unique: each name is mapped to an id.
// channel: returns the name of the channel used by the provider to send notifications. A channel can only be served by one provider.
pub interface NotificationProvider {
	name() string
	channel() string
	send(notification NotificationData) !NotificationResult
}
