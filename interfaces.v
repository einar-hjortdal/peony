module main

// TODO CacheProvider
// TODO EmailProvider
// TODO PaymentProvider
// TODO FulfillmentProvider

pub struct FileRequest {
	name      string
	mime_type string
	content   string
}

pub struct FileData {
	id  string
	url string
}

// WIP
// TODO consider users may want to use anything from local file system and amazon s3
pub interface BlobProvider {
	create(FileRequest) !FileData
	delete([]string) !
}
