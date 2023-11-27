module main

import vweb
import models

// TODO
// all of these methods: only get public and delete_at = null
@['/storefront/posts'; get]
pub fn (mut app App) storefront_posts_get() vweb.Result {
	fn_name := 'storefront_posts_get'

	params := models.PostListParams{
		post_type: 'post'
		deleted: false
	}

	posts := models.post_list(mut app.db, params) or { return app.send_error(err, fn_name) }
	return app.json(posts)
}

// TODO maybe ID does not exist
@['/storefront/posts/:id'; get]
pub fn (mut app App) storefront_post_get_by_id(id string) vweb.Result {
	fn_name := 'storefront_post_get_by_id'

	posts := models.post_retrieve_by_id(mut app.db, id) or { return app.send_error(err, fn_name) }
	return app.json(posts)
}

@['/storefront/posts/handle/:handle'; get]
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

@['/storefront/pages'; get]
pub fn (mut app App) storefront_pages_get() vweb.Result {
	fn_name := 'storefront_pages_get'

	params := models.PostListParams{
		post_type: 'page'
		deleted: false
	}

	pages := models.post_list(mut app.db, params) or { return app.send_error(err, fn_name) }
	return app.json(pages)
}
