module main

// vlib
import vweb
import json
// local
import models

// admin_posts_get is the same as storefront_posts_get with with authentication required.
// Requires authorization.
// TODO query parameters for sorting and filtering
['/admin/posts'; get]
pub fn (mut app App) admin_posts_get() vweb.Result {
	fn_name := 'admin_posts_get'

	_, mut err := app.check_user_auth()
	if err.code() != 0 {
		return app.send_error(err, fn_name)
	}

	posts := models.post_list(mut app.db, 'post') or { return app.send_error(err, fn_name) }
	return app.json(posts)
}

struct AdminPostsPostRequest {
	post_type  string   [json: postType] // must be either 'post' or 'page'
	status     string
	featured   bool
	visibility string
	title      string // required
	subtitle   string
	content    string
	handle     string
	excerpt    string
	metadata   string   [raw]
	authors    []string
}

// admin_posts_post allows an author to create a post.
// Requires authorization.
['/admin/posts'; post]
pub fn (mut app App) admin_posts_post() vweb.Result {
	fn_name := 'admin_posts_post'

	v, mut err := app.check_user_auth()
	if err.code() != 0 {
		return app.send_error(err, fn_name)
	}

	body := json.decode(AdminPostsPostRequest, app.req.data) or {
		return app.send_error(err, fn_name)
	}

	new_post_id := app.luuid_generator.v2() or { return app.send_error(err, fn_name) }

	mut post := models.PostWriteable{
		status: body.status
		featured: body.featured
		visibility: body.visibility
		title: body.title
		subtitle: body.subtitle
		content: body.content
		handle: body.handle
		excerpt: body.excerpt
		metadata: body.metadata
		authors: body.authors
	}

	post.create(mut app.db, v.user.id, new_post_id, body.post_type) or {
		return app.send_error(err, fn_name)
	}

	retrieved_post := models.post_retrieve_by_id(mut app.db, new_post_id) or {
		return app.send_error(err, fn_name)
	}

	return app.json(retrieved_post)
}

['/admin/posts/:id'; get]
pub fn (mut app App) admin_post_get_by_id(id string) vweb.Result {
	fn_name := 'admin_post_get_by_id'

	_, mut err := app.check_user_auth()
	if err.code() != 0 {
		return app.send_error(err, fn_name)
	}

	retrieved_post := models.post_retrieve_by_id(mut app.db, id) or {
		return app.send_error(err, fn_name)
	}

	return app.json(retrieved_post)
}

// admin_post_update allows an author to update a post
// Requires authorization.
['/admin/posts/:id'; post]
pub fn (mut app App) admin_post_update(id string) vweb.Result {
	fn_name := 'admin_post_update'

	v, mut err := app.check_user_auth()
	if err.code() != 0 {
		return app.send_error(err, fn_name)
	}

	mut body := json.decode(models.PostWriteable, app.req.data) or {
		return app.send_error(err, fn_name)
	}

	body.update(mut app.db, id, v.user.id) or { return app.send_error(err, fn_name) }

	retrieved_post := models.post_retrieve_by_id(mut app.db, id) or {
		return app.send_error(err, fn_name)
	}

	return app.json(retrieved_post)
}

/*
*
* Page
*
*/

// admin_pages_get is the same as storefront_pages_get with with authentication required.
// Requires authorization.
['/admin/pages'; get]
pub fn (mut app App) admin_pages_get() vweb.Result {
	fn_name := 'admin_pages_get'

	_, mut err := app.check_user_auth()
	if err.code() != 0 {
		return app.send_error(err, fn_name)
	}

	pages := models.post_list(mut app.db, 'page') or { return app.send_error(err, fn_name) }

	return app.json(pages)
}
