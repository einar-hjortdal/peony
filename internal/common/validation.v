module common

pub fn email_is_valid(e string) ! {
	if e.len > 254 {
		return error('email too long')
	}

	// a@b.cd
	if e.len < 6 {
		return error('email too short')
	}

	// TODO contains @
	// TODO illegal characters
}
