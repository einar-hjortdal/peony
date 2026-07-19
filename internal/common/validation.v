module common

// TODO local part may be within quotes, they should be stripped before checking if it starts/ends with .
fn validate_local_part(s string) ! {
	if s.len > 64 {
		return error('local-part too long')
	}

	if s.starts_with('.') || s.ends_with('.') {
		return error('local-part cannot start nor end with `.`')
	}

	if s.contains('..') {
		return error('local-part cannot contain sequences of `.`')
	}
}

fn validate_domain_part(s string) ! {
	if s.starts_with('.') {
		return error('domain-part cannot start with `.`')
	}

	if !s.contains('.') {
		return error('domain-part does not contain `.`')
	}
}

pub fn email_is_valid(e string) ! {
	if e.len > 254 {
		return error('email too long')
	}

	if e.len < 6 { // a@b.cd
		return error('email too short')
	}

	at_idx := e.last_index('@') or { return error('missing `@`') }
	if at_idx == 0 {
		return error('missing local-part')
	}

	if at_idx == e.len - 1 {
		return error('missing domain-part')
	}

	validate_local_part(e[..at_idx])!
	validate_domain_part(e[at_idx + 1..])!
}
