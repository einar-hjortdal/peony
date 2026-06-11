module conduit

import einar_hjortdal.firebird
import record

pub fn password_details_get(mut tx firebird.ClientTransaction, p PasswordDetailsGetParams) !PasswordDetails {
	password_details := record.password_details_get(mut tx, p) or {
		return new_error_internal('Failed to get password_parameters', err.msg())
	}
	return password_details
}

pub fn password_details_create(mut tx firebird.ClientTransaction, id ID, function_name string, parameters string, hash []u8) ! {
	record.password_details_create(mut tx, id, function_name, parameters, hash) or {
		return new_error_internal('Failed to create password_parameters', err.msg())
	}
}

