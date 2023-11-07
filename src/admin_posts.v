module main

// vlib
import vweb
import json
// local
import models
import utils

// admin_posts_get is the same as storefront_posts_get with with authentication required.
// Requires authorization.
// TODO query parameters for sorting and filtering
['/admin/posts'; get]
pub fn (mut app App) admin_posts_get() vweb.Result {
	_, mut e := app.check_user_auth()
	if e.code() != 0 {
		app.set_status(401, 'Unauthorized')
		return app.json(e)
	}

	posts := models.post_list(mut app.db, 'post') or {
		println(err)
		app.logger.debug(err.msg())
		app.set_status(500, 'Internal server error')
		e = utils.new_peony_error(0, err.msg())
		return app.json(e)
	}
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
	v, mut e := app.check_user_auth()
	if e.code() != 0 {
		app.set_status(401, 'Unauthorized')
		return app.json(e)
	}

	body := json.decode(AdminPostsPostRequest, app.req.data) or {
		app.logger.debug('Failed to decode JSON body into AdminPostsPostRequest struct')
		app.set_status(422, 'Invalid request')
		e = utils.new_peony_error(5, 'Could not decode AdminPostsPostRequest')
		return app.json(e)
	}

	if body.post_type == '' {
		app.logger.debug('AdminPostsPostRequest.post_type missing')
		app.set_status(422, 'Invalid request')
		e = utils.new_peony_error(5, 'Post type is required')
		return app.json(e)
	}

	if body.post_type != 'post' && body.post_type != 'page' {
		app.logger.debug('AdminPostsPostRequest.post_type is neither post nor page')
		app.set_status(400, 'Bad Request')
		e = utils.new_peony_error(400, 'postType must be either post or page')
		return app.json(e)
	}

	if body.title == '' {
		app.logger.debug('AdminPostsPostRequest.title missing')
		app.set_status(422, 'Invalid request')
		e = utils.new_peony_error(5, 'Post title is required')
		return app.json(e)
	}

	new_post_id := app.luuid_generator.v2() or {
		app.set_status(500, 'Internal server error')
		e = utils.new_peony_error(500, err.msg())
		return app.json(e)
	}

	mut post := models.PostWriteable{
		status: body.status
		featured: body.featured
		visibility: body.visibility
		title: body.title
		subtitle: body.subtitle
		content: body.content
		handle: body.handle
		metadata: body.metadata
		authors: body.authors
	}

	post.create(mut app.db, v.user.id, new_post_id, body.post_type) or {
		app.logger.debug('admin_posts_post: ${err.msg()}')
		app.set_status(500, 'Internal server error')
		e = utils.new_peony_error(5, err.msg())
		return app.json(e)
	}

	retrieved_post := models.post_retrieve_by_id(mut app.db, new_post_id) or {
		app.logger.debug('admin_posts_post: ${err.msg()}')
		app.set_status(500, 'Internal server error')
		e = utils.new_peony_error(5, err.msg())
		return app.json(e)
	}

	return app.json(retrieved_post)
}

['/admin/posts/:id'; get]
pub fn (mut app App) admin_post_get_by_id(id string) vweb.Result {
	_, mut e := app.check_user_auth()
	if e.code() != 0 {
		app.set_status(401, 'Unauthorized')
		return app.json(e)
	}

	retrieved_post := models.post_retrieve_by_id(mut app.db, id) or {
		app.logger.debug('admin_post: ${err.msg()}')
		app.set_status(500, 'Internal server error')
		e = utils.new_peony_error(5, err.msg())
		return app.json(e)
	}

	return app.json(retrieved_post)
}

// admin_post_update allows an author to update a post
// Requires authorization.
['/admin/posts/:id'; post]
pub fn (mut app App) admin_post_update(id string) vweb.Result {
	v, mut e := app.check_user_auth()
	if e.code() != 0 {
		app.set_status(401, 'Unauthorized')
		return app.json(e)
	}

	mut body := json.decode(models.PostWriteable, app.req.data) or {
		app.logger.debug('Failed to decode JSON body into models.PostWriteable struct')
		app.set_status(400, 'Invalid request body')
		e = utils.new_peony_error(422, 'Could not decode request body to models.PostWriteable')
		return app.json(e)
	}

	// TODO create utility functions to validate fields such as title?
	// Must be validated at the controller level to send useful error message back to client
	// Model should not assume valid input is provided, but are not tasked with useful error messages
	// in case of bad input.
	if body.title == '' {
		app.logger.debug('admin_post_update: models.PostWriteable.title missing')
		app.set_status(422, 'Invalid request')
		e = utils.new_peony_error(5, 'Post title is required')
		return app.json(e)
	}

	body.update(mut app.db, id, v.user.id) or {
		app.logger.debug('admin_post_update: ${err.msg()}')
		app.set_status(500, 'Database error')
		e = utils.new_peony_error(500, 'Database error: ${err.msg()}')
		return app.json(e)
	}

	retrieved_post := models.post_retrieve_by_id(mut app.db, id) or {
		app.logger.debug('admin_post_update: ${err.msg()}')
		app.set_status(500, 'Database error')
		e = utils.new_peony_error(5, 'Database error: ${err.msg()}')
		return app.json(e)
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
	_, mut e := app.check_user_auth()
	if e.code() != 0 {
		app.set_status(401, 'Unauthorized')
		return app.json(e)
	}

	pages := models.post_list(mut app.db, 'page') or {
		app.logger.debug(err.msg())
		app.set_status(500, 'Internal server error')
		e = utils.new_peony_error(0, err.msg())
		return app.json(e)
	}
	return app.json(pages)
}
