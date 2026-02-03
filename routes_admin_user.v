module peony

import json
import veb

// lists users
@['/admin/users'; get]
pub fn (mut app App) admin_user_list(mut ctx Context) veb.Result {
	p := hygienise_user_list_request_query(ctx.query) or {
		if err is InternalError {
			return handle_error_400(mut ctx, err.message, err.details)
		}
		return handle_error_unhandled(mut ctx, err.msg(), 'hygienise_user_list_request_query')
	}

	return conduit_user_list(mut app, mut ctx, p)
}

// creates a user
@['/admin/users'; post]
pub fn (mut app App) admin_users_post(mut ctx Context) veb.Result {
	p := json.decode(UserCreateRequest, ctx.req.data) or {
		return handle_error_400(mut ctx, 'Could not decode UserCreateRequest', err.msg())
	}

	if p.email == '' {
		return handle_error_400(mut ctx, error_field_empty, 'email')
	}

	if p.password == '' {
		return handle_error_400(mut ctx, error_field_empty, 'password')
	}

	email_is_valid(p.email) or { return handle_error_400(mut ctx, 'invalid email', err.msg()) }

	// TODO role

	if first_name := p.first_name {
		if utf8_str_visible_length(first_name) > max_length_first_name {
			return handle_error_400(mut ctx, 'first_name too long', 'first_name can be at most ${max_length_first_name} UTF8 characters long')
		}
	}

	if last_name := p.last_name {
		if utf8_str_visible_length(last_name) > max_length_last_name {
			return handle_error_400(mut ctx, 'last_name too long', 'last_name can be at most ${max_length_last_name} UTF8 characters long')
		}
	}

	if image := p.image {
		if alt := image.alt {
			if utf8_str_visible_length(alt) > max_length_alt {
				return handle_error_400(mut ctx, 'alt too long', 'alt can be at most ${max_length_alt} UTF8 characters long')
			}
		}
	}

	return conduit_user_create(mut app, mut ctx, p)
}

// requests a password reset
// sends a password reset email using the email provider
// ['/admin/users/password-token'; post]
// body: {email: string}

// reset password
// ['/admin/users/reset_password'; post]
// body: {
// token: string
// password: string
// }

// retrieves a user details
@['/admin/users/:user_id'; get]
pub fn (mut app App) admin_users_id_get(mut ctx Context, user_id string) veb.Result {
	user_id_bin := id_string_to_bin(user_id) or {
		return handle_error_400(mut ctx, error_id_invalid, 'user_id')
	}
	return conduit_user_get_by_id(mut app, mut ctx, user_id_bin)
}

// updates a user
@['/admin/users/:user_id'; post]
pub fn (mut app App) admin_users_id_post(mut ctx Context, user_id string) veb.Result {
	user_id_bin := id_string_to_bin(user_id) or {
		return handle_error_400(mut ctx, error_id_invalid, 'user_id')
	}

	p := json.decode(UserUpdateRequest, ctx.req.data) or {
		return handle_error_400(mut ctx, 'Could not decode UserUpdateRequest', err.msg())
	}

	if email := p.email {
		email_is_valid(email) or { return handle_error_400(mut ctx, 'invalid email', err.msg()) }
	}

	// TODO role

	if first_name := p.first_name {
		if utf8_str_visible_length(first_name) > max_length_first_name {
			return handle_error_400(mut ctx, 'first_name too long', 'first_name can be at most ${max_length_first_name} UTF8 characters long')
		}
	}

	if last_name := p.last_name {
		if utf8_str_visible_length(last_name) > max_length_last_name {
			return handle_error_400(mut ctx, 'last_name too long', 'last_name can be at most ${max_length_last_name} UTF8 characters long')
		}
	}

	if image := p.image {
		if alt := image.alt {
			if utf8_str_visible_length(alt) > max_length_alt {
				return handle_error_400(mut ctx, 'alt too long', 'alt can be at most ${max_length_alt} UTF8 characters long')
			}
		}
	}

	return conduit_user_update(mut app, mut ctx, user_id_bin, p)
}

// deletes a user
@['/admin/users/:user_id'; delete]
pub fn (mut app App) admin_users_id_delete(mut ctx Context, user_id string) veb.Result {
	user_id_bin := id_string_to_bin(user_id) or {
		return handle_error_400(mut ctx, error_id_invalid, 'user_id')
	}

	return conduit_user_delete(mut app, mut ctx, user_id_bin)
}
