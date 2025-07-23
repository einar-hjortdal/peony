module peony

// TODO CacheProvider
// TODO EmailProvider
// TODO PaymentProvider
// TODO FulfillmentProvider

// WIP
// TODO consider users may want to use anything from local file system and amazon s3
pub interface BlobProvider {
	create(FileRequest) !FileData
	delete([]string) !
}
