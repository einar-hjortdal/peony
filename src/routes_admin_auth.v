module main

import veb

// retrieves current user data
@['/admin/auth/'; get]
fn (app App) admin_auth_get(mut ctx Context) veb.Result {
	return ctx.text('ok')
}

// log in user
@['/admin/auth/'; post]
fn (app App) admin_auth_post(mut ctx Context) veb.Result {
	// json body: email, password
	return ctx.text('ok')
}

// log out user
@['/admin/auth/'; del]
fn (app App) admin_auth_del(mut ctx Context) veb.Result {
	return ctx.text('ok')
}
