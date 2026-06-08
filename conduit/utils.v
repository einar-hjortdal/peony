module conduit

import net.http
import einar_hjortdal.luuid
import record

pub const error_database_data_malformed = 'Data retrieved from database is malformed'

pub const min_fetch = i32(1)
pub const max_fetch = i32(250) // https://github.com/einar-hjortdal/firebird/issues/1
pub const offset_default = record.offset_default
pub const order_asc = record.order_asc
pub const order_desc = record.order_desc
pub const order_default = record.order_default

pub type ID = record.ID

pub fn new_id(mut g luuid.Generator) ID {
	return record.new_id(mut g)
}

pub fn id_from_string(s string) !ID {
	return record.id_from_string(s)
}

// PeonyError contains the appropriate http status code for the error.
pub struct PeonyError {
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

pub fn (e PeonyError) status() http.Status {
	return e.status_code
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

pub fn new_error_fetch_zero() PeonyError {
	return new_error_bad_request('Requested 0 results', 'fetch cannot be 0')
}

fn make_identifiable_map[T](identifiables []T) (map[string]T, []ID) {
	mut map_res := map[string]T{}
	mut arr_res := []ID{len: identifiables.len}
	for i := 0; i < identifiables.len; i++ {
		identifiable := identifiables[i]
		id := identifiable.id()
		map_res[id.string()] = identifiable
		arr_res[i] = id
	}
	return map_res, arr_res
}
