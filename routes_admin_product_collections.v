module peony

import veb
import json

@['/admin/collections'; get]
fn (mut app App) admin_collections_get(mut ctx Context) veb.Result {
	p := extract_retrieve_collections_params(ctx.query)

	collections := app.retrieve_collections(p) or {
		return handle_error_500(mut ctx, 'Could not retrieve collections ', err.msg())
	}

	return ctx.json(collections)
}

@['/admin/collections'; post]
fn (mut app App) admin_collections_post(mut ctx Context) veb.Result {
	data := json.decode(CollectionData, ctx.req.data) or {
		return handle_error_400(mut ctx, 'Could not decode CollectionData ', err.msg())
	}

	app.create_collection(data) or {
		return handle_error_500(mut ctx, 'Could not create collection ', err.msg())
	}

	return ctx.no_content()
}
