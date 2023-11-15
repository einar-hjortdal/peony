module main

// vlib
import vweb
// local
import models
import utils

/*
*
* authors
*
*/

// storefront_authors_get lists the subset of users that have posts associated with them.
@['/storefront/authors'; get]
pub fn (mut app App) storefront_authors_get() vweb.Result {
	users := models.user_list_authors(mut app.db) or {
		app.logger.debug(err.msg())
		app.set_status(500, 'Internal server error')
		peony_error := utils.new_peony_error(500, err.msg())
		return app.json(peony_error)
	}
	return app.json(users)
}

@['/storefront/authors/:id'; get]
pub fn (mut app App) storefront_authors_id_get(id string) vweb.Result {
	users := models.user_retrieve_author_by_id(mut app.db, id) or {
		if err is utils.PeonyError {
			app.logger.debug(err.to_string())
			app.set_status(err.code(), err.msg())
			return app.json(err)
		}
		app.logger.debug(err.msg())
		app.set_status(500, 'Internal server error')
		peony_error := utils.new_peony_error(500, err.msg())
		return app.json(peony_error)
	}
	return app.json(users)
}

@['/storefront/authors/handle/:handle'; get]
pub fn (mut app App) storefront_authors_handle_get(handle string) vweb.Result {
	users := models.user_retrieve_author_by_handle(mut app.db, handle) or {
		if err is utils.PeonyError {
			app.logger.debug(err.to_string())
			app.set_status(err.code(), err.msg())
			return app.json(err)
		}
		app.logger.debug(err.msg())
		app.set_status(500, 'Internal server error')
		peony_error := utils.new_peony_error(500, err.msg())
		return app.json(peony_error)
	}
	return app.json(users)
}
