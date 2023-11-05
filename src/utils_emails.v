module main

pub fn validate_email(email string) ! {
	if email.runes().len < 5 { // 1@3.56
		return error('email must be provided')
	}
	if email.len > 254 { // IETF RFC 3696 Errata 1690
		return error('email impossibly too long')
	}
	if !email.contains('@') {
		return error('${email} does not contain the `@` symbol')
	}
	if !email.contains('.') {
		return error('${email} does not contain a valid domain')
	}
	// TODO check illegal characters with regex?
	// TODO check max length?
}
