module peony

import veb
import net.http
import providers
import internal.errors

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
		return ctx.handle_error(errors.bad_request(error_header_missing,
			'Expected `Content-Type` header with `multipart/form-data` value'))
	}

	if content_type != 'multipart/form-data' {
		return ctx.handle_error(errors.bad_request(error_header_missing,
			'Expected `Content-Type` header with `multipart/form-data` value'))
	}

	if ctx.files.len == 0 || uploads_field_name !in ctx.files {
		return ctx.handle_error(errors.bad_request('No files provided',
			'At least one file is required, files must be submitted in the `${uploads_field_name}` field'))
	}

	mut blob_provider_instance := app.get_blob_provider_instance() or {
		return ctx.handle_error(err)
	}

	files := ctx.files[uploads_field_name]
	mut files_data := []providers.BlobFileData{len: files.len}
	for i := 0; i < files.len; i++ {
		f := files[i]
		file_data := blob_provider_instance.create(f) or {
			mut fail_deletion := false
			for k := 0; k < i; k++ {
				blob_provider_instance.delete(f.filename) or { fail_deletion = true }
			}

			if fail_deletion {
				return ctx.handle_error(errors.internal('Failed to upload file, any successfully uploaded file may have not been kept',
					'Failed to create file at index ${i} with name ${f.filename}: ${err.msg()}'))
			}

			return ctx.handle_error(errors.internal('Failed to upload file, any successfully uploaded file was deleted',
				'Failed to create file at index ${i} with name ${f.filename}: ${err.msg()}'))
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
		return ctx.handle_error(errors.bad_request(error_header_missing,
			'Expected `Content-Type` header'))
	}

	f := http.FileData{
		filename:     filename
		content_type: content_type
		data:         ctx.req.data
	}

	mut blob_provider_instance := app.get_blob_provider_instance() or {
		return ctx.handle_error(err)
	}

	file_data := blob_provider_instance.create(f) or {
		return ctx.handle_error(errors.internal('Failed to upload file', err.msg()))
	}

	return ctx.json(UploadsUploadOneResponseEnvelope{
		upload: file_data
	})
}

// delete files from the file provider
@['/admin/uploads/:id'; delete]
pub fn (mut app App) admin_uploads_id_delete(mut ctx Context, id string) veb.Result {
	mut blob_provider_instance := app.get_blob_provider_instance() or {
		return ctx.handle_error(err)
	}

	blob_provider_instance.delete(id) or {
		return ctx.handle_error(errors.internal('Failed to delete file', err.msg()))
	}

	return ctx.json(UploadsDeleteResponse{
		id:      id
		deleted: true
	})
}
