module peony

import net.http

pub struct ProviderBlobFileData {
pub:
	id  string
	url string
}

pub interface BlobProvider {
	create(http.FileData) !ProviderBlobFileData
	delete(string) !
}

pub struct Providers {
pub mut:
	blob &BlobProvider
	// tax &TaxProvider
	// email &EmailProvider
	// payment []&PaymentProvider
	// fulfillment []&FulfillmentProvider
}
