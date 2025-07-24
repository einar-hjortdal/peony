module peony

import net.http

pub struct BlobProviderFileData {
	id  string
	url string
}

pub interface BlobProvider {
	create(http.FileData) !BlobProviderFileData
	delete(string) !
}
