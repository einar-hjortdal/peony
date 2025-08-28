module peony

struct SuiteError {
	happened bool
	message  string
	details  string
}

fn new_suite_error(message string, details string) SuiteError {
	return SuiteError{
		happened: true
		message:  message
		details:  details
	}
}
