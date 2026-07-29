module common

pub fn config_error(msg string) ! {
	return error('[${lib}] ${msg}')
}
