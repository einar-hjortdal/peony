module main

import vweb
import models

['/admin/tags'; get]
pub fn (mut app App) admin_post_tags_get() vweb.Result {
	_, mut err := app.check_user_auth()
	if err.code() != 0 {
		return app.send_error(err, 'admin_post_tags_get')
	}

	post_tags := models.post_tag_list(mut app.db) or {
		return app.send_error(err, 'admin_post_tags_get')
	}

	return app.json(post_tags)
}

// ['/admin/tags'; post]

['/admin/tags/:id'; get]
pub fn (mut app App) admin_tags_get_by_id(id string) vweb.Result {
	_, mut err := app.check_user_auth()
	if err.code() != 0 {
		return app.send_error(err, 'admin_tags_get_by_id')
	}

	post_tag := models.post_tag_retrieve_by_id(mut app.db, id) or {
		return app.send_error(err, 'admin_tags_get_by_id')
	}

	return app.json(post_tag)
}

// ['/admin/tags/:id'; post]
