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

// Providers are services used by peony.
// BlobProvider stores and serves files sich as product images, videos, etc.
// EmailProvider allows peony to send transactional emails, security emails, etc..
// PaymentProvider enable peony to receive payments from customers, issue refunds, etc.
// FulfillmentProvider enable peony to schedule shipments of products, book returns, etc.
pub struct Providers {
pub mut:
	blob &BlobProvider
	// tax &TaxProvider
	// email &EmailProvider
	// payment []&PaymentProvider
	// fulfillment []&FulfillmentProvider
}
