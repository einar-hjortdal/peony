module tests

fn unwrap_or_error[T](v ?T, msg string) !T {
	res := v or { return msg }
	return res
}
