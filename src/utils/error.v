module utils

// vlib
import time
import json

const error_codes = {
	0:   'nil'
	2:   'Database Error'
	5:   'Not Allowed'
	400: 'Bad Request'
	401: 'Unauthorized'
	404: 'Not found'
	422: 'Unprocessable Content'
	500: 'Internal Server Error'
}

// PeonyError is the error type to return to clients.
//
// message and code are a superset of the HTTP status messages and codes.
// data is additional information regarding the error, for better developer experience.
// timestamp is useful for debugging.
pub struct PeonyError {
	message   string
	code      int
	data      string
	timestamp string
}

pub fn (e PeonyError) code() int {
	return e.code
}

pub fn (e PeonyError) msg() string {
	return e.message
}

pub fn (e PeonyError) data() string {
	return e.data
}

pub fn (e PeonyError) timestamp() string {
	return e.timestamp
}

pub fn (e PeonyError) to_string() string {
	return json.encode(e)
}

// new_peony_error returns a new PeonyError. A `code` of value `0` represents no errors.
pub fn new_peony_error(code int, data string) PeonyError {
	return PeonyError{
		message: utils.error_codes[code]
		code: code
		data: data
		timestamp: time.now().format_rfc3339()
	}
}
