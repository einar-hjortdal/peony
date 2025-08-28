module peony

import veb

struct SuiteError {
	Error
	message string
	details string
}

fn new_suite_error(message string, details string) SuiteError {
	return SuiteError{
		message: message
		details: details
	}
}

fn (se SuiteError) handle_suite_error(mut ctx Context) veb.Result {
	return handle_error_500(mut ctx, se.message, se.details)
}
