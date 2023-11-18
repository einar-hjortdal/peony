module main

import vweb
import utils

fn (mut app App) send_error(error IError, function_name string) vweb.Result {
	if error is utils.PeonyError {
		app.logger.debug('${function_name}: ${error}')
		app.set_status(error.code(), error.msg())
		return app.json(error)
	}
	new_peony_error := utils.new_peony_error(500, error.msg())
	app.logger.debug('${function_name} (unhandled): ${error.msg()}')
	app.set_status(new_peony_error.code(), new_peony_error.msg())
	return app.json(new_peony_error)
}
