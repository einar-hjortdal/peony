module errors

import net.http

// PeonyError contains the appropriate http status code for the error.
pub struct PeonyError {
	message     string
	details     string
	status_code http.Status
}

// implement IError
fn (e PeonyError) msg() string {
	return e.message
}

fn (e PeonyError) code() int {
	return i32(e.status_code)
}

fn new_peony_error(message string, details string, code http.Status) PeonyError {
	return PeonyError{
		message:     message
		details:     details
		status_code: code
	}
}

pub fn new_error_bad_request(message string, details string) PeonyError {
	return new_peony_error(message, details, http.Status.bad_request)
}

pub fn new_error_unauthorized(message string, details string) PeonyError {
	return new_peony_error(message, details, http.Status.unauthorized)
}

pub fn new_error_not_found(message string, details string) PeonyError {
	return new_peony_error(message, details, http.Status.not_found)
}

pub fn new_error_unprocessable_entity(message string, details string) PeonyError {
	return new_peony_error(message, details, http.Status.unprocessable_entity)
}

pub fn new_error_internal(message string, details string) PeonyError {
	return new_peony_error(message, details, http.Status.internal_server_error)
}

pub fn new_error_login() PeonyError {
	return new_error_unauthorized('Invalid email or password', '')
}
