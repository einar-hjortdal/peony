module config

import os

// parse_dot_env reads key-value pairs from an .env file
//
// This function does not handle inline comments, only comment lines
// Multiline values and string substitution are not supported
fn parse_dot_env() map[string]string {
	mut res := map[string]string{}
	file_data := os.read_file('.env') or { panic(err) }
	lines := file_data.split('\n')
	for line in lines {
		// Skip comment lines
		if line.starts_with('#') {
			continue
		}
		// Lines that contain settings must contain at least one equal sign
		if line.contains('=') {
			mut segments := line.split_nth('=', 2)
			segments[1] = segments[1].trim_space()
			// Remove surrounding quotes
			if segments[1].count('"') == 2 {
				segments[1] = segments[1].trim('"')
			} else if segments[1].count("'") == 2 {
				segments[1] = segments[1].trim("'")
			}
			res[segments[0]] = segments[1]
		}
	}
	return res
}

// add_to_env adds the key-value pairs to the environment,
// this overrides any pre-existing variable in the environment
fn add_to_env(dot_env map[string]string) {
	for key, val in dot_env {
		os.setenv(key, val, true)
	}
}

// load read settings from .env file if it exists in the current working directory,
// any key-value pair read in the .env file is then added to the environment
fn load() {
	if os.exists('.env') {
		dot_env := parse_dot_env()
		add_to_env(dot_env)
	}
}
