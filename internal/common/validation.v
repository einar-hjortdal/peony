module common

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

	local_part := e[..at_idx]
	domain_part := e[at_idx + 1..]

	if local_part.len > 64 {
		return error('local-part too long')
	}

	if local_part.starts_with('.') || local_part.ends_with('.') {
		return error('local-part cannot start nor end with `.`')
	}

	if local_part.contains('..') {
		return error('local-part cannot contain sequences of `.`')
	}

	if domain_part.starts_with('.') {
		return error('domain-part cannot start with `.`')
	}

	if !domain_part.contains('.') {
		return error('domain-part does not contain `.`')
	}
}
