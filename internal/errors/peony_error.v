module errors

import net.http

pub const database_malformed = 'Data retrieved from database is malformed'
pub const id_invalid = 'Invalid ID'

// PeonyError contains the appropriate http status code for the error.
pub struct PeonyError {
pub:
	message     string
	details     string
	status_code http.Status
}

// implement IError
pub fn (e PeonyError) msg() string {
	return e.message
}

pub fn (e PeonyError) code() int {
	return i32(e.status_code)
}

pub fn new_peony_error(message string, details string, code http.Status) PeonyError {
	return PeonyError{
		message:     message
		details:     details
		status_code: code
	}
}

pub fn bad_request(message string, details string) PeonyError {
	return new_peony_error(message, details, http.Status.bad_request)
}

pub fn unauthorized(message string, details string) PeonyError {
	return new_peony_error(message, details, http.Status.unauthorized)
}

pub fn forbidden(message string, details string) PeonyError {
	return new_peony_error(message, details, http.Status.forbidden)
}

pub fn not_found(message string, details string) PeonyError {
	return new_peony_error(message, details, http.Status.not_found)
}

pub fn conflict(message string, details string) PeonyError {
	return new_peony_error(message, details, http.Status.conflict)
}

pub fn unprocessable_entity(message string, details string) PeonyError {
	return new_peony_error(message, details, http.Status.unprocessable_entity)
}

pub fn internal(message string, details string) PeonyError {
	return new_peony_error(message, details, http.Status.internal_server_error)
}

pub fn not_implemented(message string, details string) PeonyError {
	return new_peony_error(message, details, http.Status.not_implemented)
}

pub fn login() PeonyError {
	return unauthorized('Invalid email or password', '')
}
