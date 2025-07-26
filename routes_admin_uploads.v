module peony

import net.http
import veb

const uploads_field_name = 'files'

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

	if ctx.files.len == 0 || uploads_field_name !in ctx.files {
		return handle_error(mut ctx, http.Status.bad_request, 'No files provided', 'At least one file is required, files must be submitted in the `${uploads_field_name}` field')
	}

	files := ctx.files[uploads_field_name]
	mut files_data := []BlobProviderFileData{len: files.len}
	for i := 0; i < files.len; i++ {
		f := files[i]
		file_data := app.blob_provider.create(f) or {
			mut fail_deletion := false
			for k := 0; k < i; k++ {
				app.blob_provider.delete(f.filename) or { fail_deletion = true }
			}

			if fail_deletion {
				return handle_error(mut ctx, http.Status.internal_server_error, 'Failed to upload file, any successfully uploaded file may have not been kept',
					'Failed to create file at index ${i} with name ${f.filename}: ${err.msg()}')
			}

			return handle_error(mut ctx, http.Status.internal_server_error, 'Failed to upload file, any successfully uploaded file was deleted',
				'Failed to create file at index ${i} with name ${f.filename}: ${err.msg()}')
		}

		files_data[i] = file_data
	}

	r := UploadsUploadResponseEnvelope{
		uploads: files_data
	}
	return ctx.json(r)
}

// delete files from the file provider
@['/admin/uploads/:id'; delete]
fn (mut app App) admin_uploads_id_delete(mut ctx Context, id string) veb.Result {
	app.blob_provider.delete(id) or {
		return handle_error(mut ctx, http.Status.internal_server_error, 'Failed to delete file',
			err.msg())
	}

	r := UploadsDeleteResponse{
		id:      id
		deleted: true
	}
	return ctx.json(r)
}
