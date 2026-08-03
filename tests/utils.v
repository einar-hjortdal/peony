module tests

fn unwrap_or_error[T](v ?T, msg string) !T { // https://github.com/vlang/v/issues/27867
	if res := v {
		return res
	}
	return error(msg)
}
