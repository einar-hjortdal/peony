module main

// vlib
import vweb
import json
// local
import models

@['/admin/post_tags'; get]
pub fn (mut app App) admin_post_tags_get() vweb.Result {
	fn_name := 'admin_post_tags_get'

	_, mut err := app.check_user_auth()
	if err.code() != 0 {
		return app.send_error(err, fn_name)
	}

	params := models.PostTagListParams{
		exclude_deleted: false
	}

	post_tags := models.post_tag_list(mut app.db, params) or { return app.send_error(err, fn_name) }

	return app.json(post_tags)
}

@['/admin/post_tags'; post]
pub fn (mut app App) admin_post_tags_post() vweb.Result {
	fn_name := 'admin_post_tags_post'

	v, mut err := app.check_user_auth()
	if err.code() != 0 {
		return app.send_error(err, fn_name)
	}

	mut body := json.decode(models.PostTagWriteable, app.req.data) or {
		return app.send_error(err, fn_name)
	}

	// generate a random handle if needed
	if body.handle == '' {
		body.handle = app.luuid_generator.v2() or { return app.send_error(err, fn_name) }
	}

	post_tag_id := app.luuid_generator.v2() or { return app.send_error(err, fn_name) }

	body.create(mut app.db, v.user.id, post_tag_id) or { return app.send_error(err, fn_name) }

	retrieved_post_tag := models.post_tag_retrieve_by_id(mut app.db, post_tag_id) or {
		return app.send_error(err, fn_name)
	}

	return app.json(retrieved_post_tag)
}

@['/admin/post_tags/:id'; get]
pub fn (mut app App) admin_tags_get_by_id(id string) vweb.Result {
	fn_name := 'admin_tags_get_by_id'

	_, mut err := app.check_user_auth()
	if err.code() != 0 {
		return app.send_error(err, fn_name)
	}

	post_tag := models.post_tag_retrieve_by_id(mut app.db, id) or {
		return app.send_error(err, fn_name)
	}

	return app.json(post_tag)
}

@['/admin/post_tags/:id'; post]
pub fn (mut app App) admin_post_tags_update(id string) vweb.Result {
	fn_name := 'admin_post_tags_update'

	v, mut err := app.check_user_auth()
	if err.code() != 0 {
		return app.send_error(err, fn_name)
	}

	mut body := json.decode(models.PostTagWriteable, app.req.data) or {
		return app.send_error(err, fn_name)
	}

	// generate a random handle if needed
	if body.handle == '' {
		body.handle = app.luuid_generator.v2() or { return app.send_error(err, fn_name) }
	}

	body.update(mut app.db, id, v.user.id) or { return app.send_error(err, fn_name) }

	retrieved_post_tag := models.post_tag_retrieve_by_id(mut app.db, id) or {
		return app.send_error(err, fn_name)
	}

	return app.json(retrieved_post_tag)
}

@['/admin/post_tags/:id'; delete]
pub fn (mut app App) admin_post_tags_delete(id string) vweb.Result {
	fn_name := 'admin_post_tags_delete'

	v, mut err := app.check_user_auth()
	if err.code() != 0 {
		return app.send_error(err, fn_name)
	}

	post_tag := models.post_tag_delete_by_id(mut app.db, v.user.id, id) or {
		return app.send_error(err, fn_name)
	}

	return app.json(post_tag)
}
