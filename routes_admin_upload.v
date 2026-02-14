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
		perr := new_error_bad_request(error_header_missing, 'Expected `Content-Type` header with `multipart/form-data` value')
		return ctx.handle_error(perr)
	}

	if content_type != 'multipart/form-data' {
		perr := new_error_bad_request(error_header_missing, 'Expected `Content-Type` header with `multipart/form-data` value')
		return ctx.handle_error(perr)
	}

	if ctx.files.len == 0 || uploads_field_name !in ctx.files {
		perr := new_error_bad_request('No files provided', 'At least one file is required, files must be submitted in the `${uploads_field_name}` field')
		return ctx.handle_error(perr)
	}

	files := ctx.files[uploads_field_name]
	mut files_data := []ProviderBlobFileData{len: files.len}
	for i := 0; i < files.len; i++ {
		f := files[i]
		file_data := app.providers.blob.create(f) or {
			mut fail_deletion := false
			for k := 0; k < i; k++ {
				app.providers.blob.delete(f.filename) or { fail_deletion = true }
			}

			if fail_deletion {
				perr := new_error_internal('Failed to upload file, any successfully uploaded file may have not been kept',
					'Failed to create file at index ${i} with name ${f.filename}: ${err.msg()}')
				return ctx.handle_error(perr)
			}

			perr := new_error_internal('Failed to upload file, any successfully uploaded file was deleted',
				'Failed to create file at index ${i} with name ${f.filename}: ${err.msg()}')
			return ctx.handle_error(perr)
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
		perr := new_error_bad_request(error_header_missing, 'Expected `Content-Type` header')
		return ctx.handle_error(perr)
	}

	f := http.FileData{
		filename:     filename
		content_type: content_type
		data:         ctx.req.data
	}

	file_data := app.providers.blob.create(f) or {
		perr := new_error_internal('Failed to upload file', err.msg())
		return ctx.handle_error(perr)
	}

	return ctx.json(UploadsUploadOneResponseEnvelope{
		upload: file_data
	})
}

// delete files from the file provider
@['/admin/uploads/:id'; delete]
pub fn (mut app App) admin_uploads_id_delete(mut ctx Context, id string) veb.Result {
	app.providers.blob.delete(id) or {
		perr := new_error_internal('Failed to delete file', err.msg())
		return ctx.handle_error(perr)
	}

	return ctx.json(UploadsDeleteResponse{
		id:      id
		deleted: true
	})
}
