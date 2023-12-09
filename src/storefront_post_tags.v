module main

import vweb
import models
// local
import utils

// Path: /storefront/post_tags
// Id: storefront_post_tags_get
// Summary: "Get list of PostTag"
// Description: "Returns array of PostTag"
// Produces:
// - application/json
// Param:
// - limit
// - offset
// - order
// - search
// - filter_id
// - filter_handle
// Responses:
// - 200
// - 400
// - 500
@['/storefront/post_tags'; get]
pub fn (mut app App) storefront_post_tags_get() vweb.Result {
	fn_name := 'storefront_post_tags_get'

	mut q_filter_handle := []string{}
	if 'filter_handle' in app.query {
		if app.query['filter_handle'] == '' {
			err := utils.new_peony_error(400, 'empty filter_handle query')
			return app.send_error(err, fn_name)
		}
		q_filter_handle = app.query['filter_handle'].split(',')
	}

	params := models.PostTagListParams{
		filter_handle: q_filter_handle
		filter_deleted: true
	}

	post_tags := models.post_tag_list(mut app.db, params) or { return app.send_error(err, fn_name) }

	return app.json(post_tags)
}
