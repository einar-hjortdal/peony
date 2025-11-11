module peony

import veb
import net.http

const uploads_field_name = 'files'

// retrieve a file from the file provider
// @['/admin/uploads/:id'; get]
// fn (mut app App) admin_uploads_id_get(mut ctx Context) veb.Result {
// 	return ctx.text('')
// }

// upload files to the file provider
// accepts `multipart/form-data` payloads, files should be put in the 'files' field.
@['/admin/uploads'; post]
pub fn (mut app App) admin_uploads_post(mut ctx Context) veb.Result {
	content_type := get_header_content_type(mut ctx) or {
		return handle_error_400(mut ctx, error_header_missing, 'Expected `Content-Type` header with `multipart/form-data` value')
	}

	if content_type != 'multipart/form-data' {
		return handle_error_400(mut ctx, error_header_invalid, 'Expected `Content-Type` header with `multipart/form-data` value')
	}

	if ctx.files.len == 0 || uploads_field_name !in ctx.files {
		return handle_error_400(mut ctx, 'No files provided', 'At least one file is required, files must be submitted in the `${uploads_field_name}` field')
	}

	files := ctx.files[uploads_field_name]
	mut files_data := []ProviderBlobFileData{len: files.len}
	for i := 0; i < files.len; i++ {
		f := files[i]
		file_data := app.blob_provider.create(f) or {
			mut fail_deletion := false
			for k := 0; k < i; k++ {
				app.blob_provider.delete(f.filename) or { fail_deletion = true }
			}

			if fail_deletion {
				return handle_error_500(mut ctx, 'Failed to upload file, any successfully uploaded file may have not been kept',
					'Failed to create file at index ${i} with name ${f.filename}: ${err.msg()}')
			}

			return handle_error_500(mut ctx, 'Failed to upload file, any successfully uploaded file was deleted',
				'Failed to create file at index ${i} with name ${f.filename}: ${err.msg()}')
		}

		files_data[i] = file_data
	}

	return ctx.json(UploadsUploadResponseEnvelope{
		uploads: files_data
	})
}

// uploads one file to the file provider
@['/admin/uploads/:filename'; post]
pub fn (mut app App) admin_uploads_name_post(mut ctx Context, filename string) veb.Result {
	content_type := get_header_content_type(mut ctx) or {
		return handle_error_400(mut ctx, error_header_missing, 'Expected `Content-Type` header')
	}

	f := http.FileData{
		filename:     filename
		content_type: content_type
		data:         ctx.req.data
	}

	file_data := app.blob_provider.create(f) or {
		return handle_error_500(mut ctx, 'Failed to upload file', err.msg())
	}

	return ctx.json(UploadsUploadOneResponseEnvelope{
		upload: file_data
	})
}

// delete files from the file provider
@['/admin/uploads/:id'; delete]
pub fn (mut app App) admin_uploads_id_delete(mut ctx Context, id string) veb.Result {
	app.blob_provider.delete(id) or {
		return handle_error_500(mut ctx, 'Failed to delete file', err.msg())
	}

	return ctx.json(UploadsDeleteResponse{
		id:      id
		deleted: true
	})
}
