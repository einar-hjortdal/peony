module main

import net.http
import veb
import json

@['/admin/collections'; get]
fn (mut app App) admin_collections_get(mut ctx Context) veb.Result {
	p := extract_retrieve_collections_params(ctx.query)

	collections := app.retrieve_collections(p) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Could not retrieve collections ', err.msg()))
	}

	return ctx.json(collections)
}

@['/admin/collections'; post]
fn (mut app App) admin_collections_post(mut ctx Context) veb.Result {
	data := json.decode(CollectionData, ctx.req.data) or {
		ctx.res.set_status(http.Status.bad_request)
		return ctx.json(new_peony_error('Could not decode CollectionData ', err.msg()))
	}

	app.create_collection(data) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Could not create collection ', err.msg()))
	}

	return ctx.no_content()
}
