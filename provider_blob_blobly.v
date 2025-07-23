module peony

pub struct Blobly {
	url         string
	access_keys []string
	secret_keys []string
}

pub fn new_provider_blob_blobly(url string, access_keys []string, secret_keys []string) Blobly {
	return Blobly{
		url:         url
		access_keys: access_keys
		secret_keys: secret_keys
	}
	// TODO before returning the struct, send a request to verify that the service is running and auth
	// is valid, then if successful return, otherwise panic
}

fn (b Blobly) create(f FileRequest) !FileData {
	// build request: add auth header
	return error('TODO')
}

fn (b Blobly) delete(f []string) ! {
	return error('TODO')
}
