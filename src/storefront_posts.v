module main

import vweb
import models

['/storefront/posts'; get]
pub fn (mut app App) storefront_posts_get() vweb.Result {
	posts := models.post_list(mut app.db, 'post') or {
		app.logger.debug(err.msg())
		app.set_status(500, 'Internal server error')
		peony_error := new_peony_error(500, err.msg())
		return app.json(peony_error)
	}
	return app.json(posts)
}

['/storefront/posts/:id'; get]
pub fn (mut app App) storefront_post_get_by_id(id string) vweb.Result {
	pages := models.post_retrieve_by_id(mut app.db, id) or {
		app.logger.debug(err.msg())
		app.set_status(500, 'Internal server error')
		peony_error := new_peony_error(500, err.msg())
		return app.json(peony_error)
	}
	return app.json(pages)
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
		peony_error := new_peony_error(500, err.msg())
		return app.json(peony_error)
	}
	return app.json(pages)
}
