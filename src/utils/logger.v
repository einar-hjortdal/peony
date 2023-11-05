module utils

import log
import os

// create_logger creates a log instance.
// By default the log level is set to info. Environment variables are used to change log level to debug,
// therefore this function should be invoked after the environment variables are read.
// Logging is done exclusively on the console because peony is meant to be deployed as containerized
// application.
pub fn create_logger() log.Log {
	// Set log level according to the environment
	mut log_level := log.Level.info
	if os.getenv('DEBUG') == 'true' {
		log_level = log.Level.debug
	}

	mut logger := log.Log{
		level: log_level
		output_target: log.LogTarget.console
	}
	return logger
}
