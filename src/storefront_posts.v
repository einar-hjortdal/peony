module main

import vweb
import models
import utils

['/storefront/posts'; get]
pub fn (mut app App) storefront_posts_get() vweb.Result {
	posts := models.post_list(mut app.db, 'post') or {
		app.logger.debug(err.msg())
		app.set_status(500, 'Internal server error')
		peony_error := utils.new_peony_error(500, err.msg())
		return app.json(peony_error)
	}
	return app.json(posts)
}

// TODO maybe ID does not exist
['/storefront/posts/:id'; get]
pub fn (mut app App) storefront_post_get_by_id(id string) vweb.Result {
	posts := models.post_retrieve_by_id(mut app.db, id) or {
		app.logger.debug(err.msg())
		app.set_status(500, 'Internal server error')
		peony_error := utils.new_peony_error(500, err.msg())
		return app.json(peony_error)
	}
	return app.json(posts)
}

['/storefront/posts/handle/:handle'; get]
fn (mut app App) storefront_post_get_by_handle(handle string) vweb.Result {
	post := models.post_retrieve_by_handle(mut app.db, handle) or {
		if err is utils.PeonyError {
			app.logger.debug(err.to_string())
			app.set_status(404, err.data())
			return app.json(err)
		}
		app.logger.debug(err.msg())
		app.set_status(500, 'Internal server error')
		peony_error := utils.new_peony_error(500, err.msg())
		return app.json(peony_error)
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
	pages := models.post_list(mut app.db, 'page') or {
		app.logger.debug(err.msg())
		app.set_status(500, 'Internal server error')
		peony_error := utils.new_peony_error(500, err.msg())
		return app.json(peony_error)
	}
	return app.json(pages)
}
