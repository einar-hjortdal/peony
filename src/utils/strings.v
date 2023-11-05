module utils

import strconv
import time

// parse_bool returns true if the string represents a true bool, or false if the string represents a
// false bool.
// Any of the following are accepted values: 1, t, T, TRUE, true, True, 0, f, F, FALSE, false, False
// Always call `can_parse_bool` before `parse_bool` to handle strings that cannot be parsed to bool.
pub fn parse_bool(s string) bool {
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
pub fn can_parse_bool(s string) bool {
	accepted := ['1', 't', 'T', 'TRUE', 'true', 'True', '0', 'f', 'F', 'FALSE', 'false', 'False']
	for val in accepted {
		if s == val {
			return true
		}
	}
	return false
}

// is true returns true if both `can_parse_bool` and `parse_bool` return true
pub fn is_true(s string) bool {
	if can_parse_bool(s) && parse_bool(s) {
		return true
	} else {
		return false
	}
}

// number_to_seconds parses a string to `time.second`. Returns 0 if string cannot be parsed.
pub fn number_to_seconds(s string) time.Duration {
	seconds := strconv.parse_int(s, 10, 64) or { 0 }
	return seconds * time.second
}
