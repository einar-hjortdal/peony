module main

import vweb
import models

['/storefront/posts'; get]
pub fn (mut app App) storefront_posts_get() vweb.Result {
	fn_name := 'storefront_posts_get'

	posts := models.post_list(mut app.db, 'post') or { return app.send_error(err, fn_name) }
	return app.json(posts)
}

// TODO maybe ID does not exist
['/storefront/posts/:id'; get]
pub fn (mut app App) storefront_post_get_by_id(id string) vweb.Result {
	fn_name := 'storefront_post_get_by_id'

	posts := models.post_retrieve_by_id(mut app.db, id) or { return app.send_error(err, fn_name) }
	return app.json(posts)
}

['/storefront/posts/handle/:handle'; get]
fn (mut app App) storefront_post_get_by_handle(handle string) vweb.Result {
	fn_name := 'storefront_post_get_by_handle'

	post := models.post_retrieve_by_handle(mut app.db, handle) or {
		return app.send_error(err, fn_name)
	}
	return app.json(post)
}

/*
*
* Page
*
*/

['/storefront/pages'; get]
pub fn (mut app App) storefront_pages_get() vweb.Result {
	fn_name := 'storefront_pages_get'

	pages := models.post_list(mut app.db, 'page') or { return app.send_error(err, fn_name) }
	return app.json(pages)
}
