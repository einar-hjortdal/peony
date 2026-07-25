module conduit

import record
import einar_hjortdal.firebird
import internal.common
import internal.errors

// invalidates any currently-valid token for the user and creates a new one
pub fn password_reset_token_create_admin(
	mut tx firebird.ClientTransaction,
	token_id common.ID,
	user_id common.ID,
	password_hash []u8,
	password_salt []u8,
	password_details_id common.ID) ! {
	record.password_reset_token_delete_by_user(mut tx, user_id) or {
		return errors.internal('Failed to delete existing valid tokens for the user', err.msg())
	}

	record.password_reset_token_create(mut tx, record.PasswordResetTokenCreateParams{
		id:                  token_id
		user_id:             user_id
		password_hash:       password_hash
		password_salt:       password_salt
		password_details_id: password_details_id
	}) or { return errors.internal('Failed to create password_reset_token', err.msg()) }
}

pub fn password_reset_token_user_get(mut tx firebird.ClientTransaction, user_id common.ID) !PasswordResetTokenUser {
	token := record.password_reset_token_user_get(mut tx, user_id) or {
		match err {
			record.NotFound {
				return errors.not_found('user has no valid password reset tokens',
					'password_reset_token_user_get returned NotFound')
			}
			else {
				return errors.internal('Failed to get password_reset_token', err.msg())
			}
		}
	}
	return token
}
