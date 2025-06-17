module main

import einar_hjortdal.firebird

struct PeonySuccess {
	success bool
}

fn new_peony_success() PeonySuccess {
	return PeonySuccess{
		success: true
	}
}

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

fn login_error() (string, string) {
	return 'Invalid email or password', 'No further details'
}

// count is the number of items in the database
// offset is the number of items skipped
// fetch is the number of items requested
struct ListResponse[T] {
	items  []T
	count  i32
	offset i32
	fetch  i32
}

struct UserResponse {
	id         string
	handle     string
	email      string
	role       string
	created_at firebird.DateTime
	updated_at firebird.DateTime
	deleted_at firebird.DateTime @[omitempty]
	first_name string            @[omitempty]
	last_name  string            @[omitempty]
}

fn format_user_response(u User) UserResponse {
	return UserResponse{
		id:         u.id
		handle:     u.handle
		email:      u.email
		role:       u.role
		created_at: u.created_at
		updated_at: u.updated_at
		deleted_at: u.deleted_at
		first_name: u.first_name
		last_name:  u.last_name
	}
}
