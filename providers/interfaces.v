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

pub struct NotificationContent {
	subject ?string
	text    ?string
	html    ?string
}

pub struct NotificationData {
	to   string
	from ?string
	// attachments: ?
	channel       string
	template_name string
	data          ?string
	provider_data ?string
	content       ?NotificationContent
}

pub interface NotificationProvider {
	send(notification NotificationData)
}
