module main

import time
import json

const error_codes = {
	0:   'nil'
	2:   'db_error'
	4:   'not_found'
	5:   'not_allowed'
	400: 'Bad Request'
	401: 'Unauthorized'
	422: 'Unprocessable Content'
	500: 'Internal Server Error'
	7:   'unexpected_state'
	8:   'payment_authorization_error'
}

// PeonyError is the error type to return to clients.
//
// message is a description of the error.
// code is a code that identifies the error.
// data is additional information regarding the error.
// timestamp is a unix epoch.
struct PeonyError {
pub:
	message   string
	code      int
	data      string
	timestamp string
}

// new_peony_error returns a new PeonyError. A `code` of value `0` represents no errors.
fn new_peony_error(code int, data string) PeonyError {
	return PeonyError{
		message: error_codes[code]
		code: code
		data: data
		timestamp: time.now().format_rfc3339()
	}
}

fn (e PeonyError) to_string() string {
	return json.encode(e)
}
