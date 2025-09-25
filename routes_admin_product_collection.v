module peony

import veb

@['/admin/collections'; get]
fn (mut app App) admin_collections_get(mut ctx Context) veb.Result {
	return ctx.text('TODO')
}

@['/admin/collections'; post]
fn (mut app App) admin_collections_post(mut ctx Context) veb.Result {
	return ctx.text('TODO')
}
