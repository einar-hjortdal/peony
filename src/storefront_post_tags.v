module main

import vweb
import db.mysql
import models

@['/storefront/post_tags'; get]
pub fn (mut app App) storefront_post_tags_get() vweb.Result {
	fn_name := 'storefront_post_tags_get'

	_, mut err := app.check_user_auth()
	if err.code() != 0 {
		return app.send_error(err, fn_name)
	}

	post_tags := models.post_tag_list(mut app.db) or { return app.send_error(err, fn_name) }

	return app.json(post_tags)
}

@['/storefront/post_tags/:id'; get]
pub fn (mut app App) storefront_post_tags_get_by_id(id string) vweb.Result {
	return app.storefront_post_tag_retrieve(id, models.post_tag_retrieve_by_id)
}

@['/storefront/post_tags/handle/:handle'; get]
pub fn (mut app App) storefront_post_tags_get_by_handle(handle string) vweb.Result {
	return app.storefront_post_tag_retrieve(handle, models.post_tag_retrieve_by_handle)
}

fn (mut app App) storefront_post_tag_retrieve(id_or_handle string, retrieve_fn fn (mut mysql.DB, string) !models.PostTag) vweb.Result {
	fn_name := 'storefront_post_tag_retrieve'

	_, mut err := app.check_user_auth()
	if err.code() != 0 {
		return app.send_error(err, fn_name)
	}

	post_tag := retrieve_fn(mut app.db, id_or_handle) or { return app.send_error(err, fn_name) }

	return app.json(post_tag)
}
