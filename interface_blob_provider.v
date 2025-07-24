module peony

pub struct FileRequest {
	name      string
	mime_type string
	content   string
}

pub struct FileData {
	id  string
	url string
}

pub interface BlobProvider {
	create(FileRequest) !FileData
	delete(string) !
}
