module peony

import net.http
import veb

// retrieve a file from the file provider
// @['/admin/uploads/:id'; get]
// fn (mut app App) admin_uploads_id_get(mut ctx Context) veb.Result {
// 	return ctx.text('')
// }

// upload files to the file provider
// expects `multipart/form-data` payload
@['/admin/uploads'; post]
fn (mut app App) admin_uploads_post(mut ctx Context) veb.Result {
	content_type := ctx.req.header.get(http.CommonHeader.content_type) or {
		return handle_error(mut ctx, http.Status.bad_request, error_header_missing, 'Expected `Content-Type` header with `multipart/form-data` value')
	}

	if content_type != 'multipart/form-data' {
		return handle_error(mut ctx, http.Status.bad_request, error_header_invalid, 'Expected `Content-Type` header with `multipart/form-data` value')
	}

	// send images to blobly
	// res := app.blob_provider.upload(ctx.req, ctx.files) or {
	// }

	// return error / return list with key and url for each uploaded file
	return ctx.json('TODO')
}

// delete files from the file provider
// @['/admin/uploads/:id'; delete]
// fn (mut app App) admin_uploads_id_delete(mut ctx Context) veb.Result {
// 	return ctx.text('')
// }
