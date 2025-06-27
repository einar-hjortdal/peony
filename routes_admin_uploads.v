module main

import veb

@['/admin/uploads'; post]
fn (mut app App) admin_uploads_post(mut ctx Context) veb.Result {
	// TODO send images to blobly
	// receive multipart formdata
	// return list with key and url for each uploaded file
	// key is the file name, I think?
	return ctx.text('')
}
