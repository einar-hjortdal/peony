module main

import strconv
import time

const lib = 'peony'

fn format_error_message(message string) string {
	return '[${lib}] ${message}'
}

fn string_or_default(s string, d string) string {
	if s != '' {
		return s
	}
	return d
}

// parse_bool returns true if the string represents a true bool, or false if the string represents a
// false bool.
// Any of the following are accepted values: 1, t, T, TRUE, true, True, 0, f, F, FALSE, false, False
// Always call `can_parse_bool` before `parse_bool` to handle strings that cannot be parsed to bool.
fn parse_bool(s string) bool {
	string_true := ['1', 't', 'T', 'TRUE', 'true', 'True']
	for value in string_true {
		if s == value {
			return true
		}
	}
	return false
}

// can_parse_bool returns true if the string can be parsed to a boolean with parse_bool, otherwise it
// returns false.
fn can_parse_bool(s string) bool {
	accepted := ['1', 't', 'T', 'TRUE', 'true', 'True', '0', 'f', 'F', 'FALSE', 'false', 'False']
	for val in accepted {
		if s == val {
			return true
		}
	}
	return false
}

fn is_true(s string) bool {
	if can_parse_bool(s) {
		return parse_bool(s)
	} else {
		return false
	}
}

// number_to_seconds parses a string to `time.second`. Returns 0 if string cannot be parsed.
fn number_to_seconds(s string) time.Duration {
	seconds := strconv.parse_int(s, 10, 64) or { 0 }
	return seconds * time.second
}
