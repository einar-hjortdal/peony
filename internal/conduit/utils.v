module conduit

import net.http
import einar_hjortdal.luuid
import common

pub const error_database_data_malformed = 'Data retrieved from database is malformed'

const min_fetch = common.min_fetch
const max_fetch = common.max_fetch
const offset_default = common.offset_default
const order_asc = common.order_asc
const order_desc = common.order_desc
const order_default = common.order_default

pub type ID = common.ID

pub fn new_id(mut g luuid.Generator) ID {
	return common.new_id(mut g)
}

pub fn id_from_string(s string) !ID {
	return common.id_from_string(s)
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
