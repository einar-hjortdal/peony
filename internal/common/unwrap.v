module common

pub fn unwrap_option_or[T](option_type ?T, default_value T) T {
	if some_value := option_type {
		return some_value
	}
	return default_value
}

pub fn unwrap_option_or_option[T](option_type ?T, default_option ?T) ?T {
	if some_value := option_type {
		return some_value
	}
	return default_option
}
