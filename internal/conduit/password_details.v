module conduit

import einar_hjortdal.firebird
import record
import internal.errors
import internal.common

pub fn password_details_get(mut tx firebird.ClientTransaction, p PasswordDetailsGetParams) !PasswordDetails {
	password_details := record.password_details_get(mut tx, p) or {
		return errors.internal('Failed to get password_details', err.msg())
	}
	return password_details
}

pub fn password_details_create(
	mut tx firebird.ClientTransaction,
	id common.ID,
	function_name string,
	parameters string,
	hash []u8) ! {
	record.password_details_create(mut tx, id, function_name, parameters, hash) or {
		return errors.internal('Failed to create password_details', err.msg())
	}
}
