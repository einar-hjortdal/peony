module peony

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
