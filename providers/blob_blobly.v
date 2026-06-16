module providers

import crypto.hmac
import crypto.sha256
import json
import log
import net.http

const blobly_blobs_dirname = 'peony'

pub struct BloblyClient {
	url        string
	access_key string
	secret_key string
}

pub fn new_provider_blob_blobly(url string, access_key string, secret_key string) !&BloblyClient {
	bp := &BloblyClient{
		url:        url
		access_key: access_key
		secret_key: secret_key
	}
	bp.init()!
	return bp
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

struct BloblyEntries {
	entries []string
}

fn (b BloblyClient) new_signed_http_request(method http.Method, url string, data string) !http.Request {
	signature := hmac.new(b.secret_key.bytes(), b.access_key.bytes(), sha256.sum, sha256.block_size)
	header_content := '${b.access_key}$${signature.bytestr()}'
	mut request := http.new_request(method, url, data)
	request.add_custom_header('Blobly-Authorization', header_content)!
	return request
}

fn (b BloblyClient) blobs_dir_exist() !bool {
	url := '${b.url}/api/directories'
	request := b.new_signed_http_request(http.Method.get, url, '')!
	response := request.do()!
	if response.status_code != 200 {
		return error(response.body)
	}

	body := json.decode(BloblyEntries, response.body)!
	return body.entries.contains(blobly_blobs_dirname)
}

fn (b BloblyClient) create_blobs_dir() ! {
	url := '${b.url}/api/files/${blobly_blobs_dirname}'
	request := b.new_signed_http_request(http.Method.post, url, '')!
	response := request.do()!
	if response.status_code != 200 {
		return error(response.body)
	}
}

fn (b BloblyClient) init() ! {
	if b.blobs_dir_exist()! {
		log.info('[provider_blob_blobly] ready')
	} else {
		log.info('[provider_blob_blobly] creating directory')
		b.create_blobs_dir()!
	}
}

// fulfill BlobProvider interface
fn (b BloblyClient) create(f http.FileData) !BlobFileData {
	url := '${b.url}/api/files/${blobly_blobs_dirname}/${f.filename}'
	request := b.new_signed_http_request(http.Method.post, url, f.data)!
	response := request.do()!

	if response.status_code == 200 {
		data := json.decode(BloblySuccess, response.body) or {
			return error('Could not decode BloblySuccess')
		}
		return BlobFileData{
			id:  data.file_name
			url: '${b.url}/public/${blobly_blobs_dirname}/${data.file_name}'
		}
	}

	data := json.decode(BloblyError, response.body) or {
		return error('Could not decode BloblyError')
	}
	return error(data.message)
}

fn (b BloblyClient) delete(filename string) ! {
	url := '${b.url}/api/files/${blobly_blobs_dirname}/${filename}'
	request := b.new_signed_http_request(http.Method.delete, url, '')!
	response := request.do()!
	if response.status_code == 200 {
		return
	}

	data := json.decode(BloblyError, response.body) or {
		return error('Could not decode BloblyError')
	}
	return error(data.message)
}

