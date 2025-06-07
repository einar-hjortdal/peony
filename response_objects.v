module main

import einar_hjortdal.firebird

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
