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
