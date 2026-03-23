module peony

import json
import veb

// lists users
@['/admin/users'; get]
pub fn (mut app App) admin_user_list(mut ctx Context) veb.Result {
	p := hygienise_user_list_request_query(ctx.query) or { return ctx.handle_error(err) }

	return conduit_user_list(mut app, mut ctx, p)
}

// creates a user
@['/admin/users'; post]
pub fn (mut app App) admin_users_post(mut ctx Context) veb.Result {
	p := json.decode(UserCreateRequest, ctx.req.data) or {
		perr := new_error_bad_request('Could not decode UserCreateRequest', err.msg())
		return ctx.handle_error(perr)
	}

	if p.email == '' {
		perr := new_error_bad_request(error_field_empty, 'email')
		return ctx.handle_error(perr)
	}

	if p.password == '' {
		perr := new_error_bad_request(error_field_empty, 'password')
		return ctx.handle_error(perr)
	}

	email_is_valid(p.email) or {
		perr := new_error_bad_request('invalid email', err.msg())
		return ctx.handle_error(perr)
	}

	// TODO role

	if first_name := p.first_name {
		if utf8_str_visible_length(first_name) > max_length_first_name {
			perr := new_error_bad_request('first_name too long', 'first_name can be at most ${max_length_first_name} UTF8 characters long')
			return ctx.handle_error(perr)
		}
	}

	if last_name := p.last_name {
		if utf8_str_visible_length(last_name) > max_length_last_name {
			perr := new_error_bad_request('last_name too long', 'last_name can be at most ${max_length_last_name} UTF8 characters long')
			return ctx.handle_error(perr)
		}
	}

	if image := p.image {
		if alt := image.alt {
			if utf8_str_visible_length(alt) > max_length_alt {
				perr := new_error_bad_request('alt too long', 'alt can be at most ${max_length_alt} UTF8 characters long')
				return ctx.handle_error(perr)
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
	parsed_user_id := id_from_string(user_id) or {
		perr := new_error_unprocessable_entity(error_id_invalid, 'user_id')
		return ctx.handle_error(perr)
	}
	return conduit_user_get_by_id(mut app, mut ctx, parsed_user_id)
}

// updates a user
@['/admin/users/:user_id'; post]
pub fn (mut app App) admin_users_id_post(mut ctx Context, user_id string) veb.Result {
	user_id_bin := id_string_to_bin(user_id) or {
		perr := new_error_bad_request(error_id_invalid, 'user_id')
		return ctx.handle_error(perr)
	}

	p := json.decode(UserUpdateRequest, ctx.req.data) or {
		perr := new_error_bad_request('Could not decode UserUpdateRequest', err.msg())
		return ctx.handle_error(perr)
	}

	if email := p.email {
		email_is_valid(email) or {
			perr := new_error_bad_request('invalid email', err.msg())
			return ctx.handle_error(perr)
		}
	}

	// TODO role

	if first_name := p.first_name {
		if utf8_str_visible_length(first_name) > max_length_first_name {
			perr := new_error_bad_request('first_name too long', 'first_name can be at most ${max_length_first_name} UTF8 characters long')
			return ctx.handle_error(perr)
		}
	}

	if last_name := p.last_name {
		if utf8_str_visible_length(last_name) > max_length_last_name {
			perr := new_error_bad_request('last_name too long', 'last_name can be at most ${max_length_last_name} UTF8 characters long')
			return ctx.handle_error(perr)
		}
	}

	if image := p.image {
		if alt := image.alt {
			if utf8_str_visible_length(alt) > max_length_alt {
				perr := new_error_bad_request('alt too long', 'alt can be at most ${max_length_alt} UTF8 characters long')
				return ctx.handle_error(perr)
			}
		}
	}

	return conduit_user_update(mut app, mut ctx, user_id_bin, p)
}

// deletes a user
@['/admin/users/:user_id'; delete]
pub fn (mut app App) admin_users_id_delete(mut ctx Context, user_id string) veb.Result {
	user_id_bin := id_string_to_bin(user_id) or {
		perr := new_error_bad_request(error_id_invalid, 'user_id')
		return ctx.handle_error(perr)
	}

	return conduit_user_delete(mut app, mut ctx, user_id_bin)
}
