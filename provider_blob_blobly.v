module peony

import crypto.hmac
import crypto.sha256
import json
import net.http

pub struct Blobly {
	url        string
	access_key string
	secret_key string
}

pub fn new_provider_blob_blobly(url string, access_key string, secret_key string) Blobly {
	return Blobly{
		url:        url
		access_key: access_key
		secret_key: secret_key
	}
	// TODO before returning the struct, send a request to verify that the service is running and auth
	// is valid, then if successful return, otherwise panic
}

struct BloblyError {
	message string
	details string
}

struct BloblySuccess {
	success              bool
	file_name            string @[json: 'fileName'; omitempty]
	file_name_compressed string @[omitempty]
}

fn (b Blobly) create(f FileRequest) !FileData {
	// build request
	signature := hmac.new(b.secret_key.bytes(), b.access_key.bytes(), sha256.sum, sha256.block_size)
	header_content := '${b.access_key}$${signature.bytestr()}'
	url := '${b.url}/${f.name}'

	mut request := http.new_request(http.Method.post, url, f.content)
	request.add_custom_header('Blobly-Authorization', header_content)!

	response := request.do()!

	if response.status_code == 200 {
		data := json.decode(BloblySuccess, response.body) or {
			return error('Could not decode BloblySuccess')
		}
		return FileData{
			id:  data.file_name
			url: '${b.url}/public/${data.file_name}'
		}
	}

	data := json.decode(BloblyError, response.body) or {
		return error('Could not decode BloblyError')
	}
	return error(data.message)
}

fn (b Blobly) delete(f []string) ! {
	return error('TODO')
}
