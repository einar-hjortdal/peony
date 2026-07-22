module conduit

pub fn password_reset_token_create(mut tx firebird.ClientTransaction, p PasswordResetTokenCreateParams) ! {
	record.password_reset_token_create(mut tx, p) or {
		return errors.internal('Failed to create password_reset_token', err.msg())
	}
}
