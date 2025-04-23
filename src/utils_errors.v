module main

// import veb
// import net.http
// import log

const lib = 'peony'

fn format_error_message(message string) string {
	return '[${lib}] ${message}'
}

// PeonyError is the error type to return to clients.
//
// message and code are a superset of the HTTP status messages and codes.
// data is additional information regarding the error, for better developer experience.
// timestamp is useful for debugging.
struct PeonyError {
	Error
	code    int
	message string
	details string
}

const error_messages = {
	0: 'unknown_error'
	1: 'database_error'
	2: 'payment_authorization_error'
	3: 'duplicate_error'
}

fn get_error_message(code int) string {
	if code in error_messages {
		return error_messages[code]
	}
	return error_messages[0]
}

fn new_peony_error(code int, details string) PeonyError {
	return PeonyError{
		message: get_error_message(code)
		code:    code
		details: details
	}
}
