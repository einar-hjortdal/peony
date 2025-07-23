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
