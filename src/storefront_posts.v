module main

// vlib
import vweb
import strconv
// local
import models
import utils

@['/storefront/posts'; get]
pub fn (mut app App) storefront_posts_get() vweb.Result {
	fn_name := 'storefront_posts_get'

	mut q_filter_tags := []string{}
	if 'filter_tags' in app.query {
		if app.query['filter_tags'] == '' {
			err := utils.new_peony_error(400, 'empty filter_tag query')
			return app.send_error(err, fn_name)
		} else {
			q_filter_tags = app.query['filter_tags'].split(',')
		}
	}

	params := models.PostListParams{
		filter_post_type: 'post'
		filter_deleted: true
		filter_tags: q_filter_tags
		limit: strconv.atoi(app.query['limit']) or { 0 }
		offset: strconv.atoi(app.query['offset']) or { 0 }
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
		filter_post_type: 'page'
		filter_deleted: true
		limit: strconv.atoi(app.query['limit']) or { 0 }
		offset: strconv.atoi(app.query['offset']) or { 0 }
	}

	pages := models.post_list(mut app.db, params) or { return app.send_error(err, fn_name) }
	return app.json(pages)
}
