module main

import net.http
import veb

@['/admin/collections'; get]
fn (mut app App) admin_collections_get(mut ctx Context) veb.Result {
	p := extract_retrieve_collections_params(ctx.query)

	collections := app.retrieve_collections(p) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Could not retrieve collections ', err.msg()))
	}

	return ctx.json(collections)
}
