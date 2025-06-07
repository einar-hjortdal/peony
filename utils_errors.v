module main

const lib = 'peony'

fn format_error_message(message string) string {
	return '[${lib}] ${message}'
}

// PeonyError is the error type to return to clients.
struct PeonyError {
	Error
	message string
	details string
}

fn new_peony_error(message string, details string) PeonyError {
	return PeonyError{
		message: message
		details: details
	}
}
