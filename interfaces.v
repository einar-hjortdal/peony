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
