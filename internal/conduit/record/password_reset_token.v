module record

import einar_hjortdal.firebird
import internal.common

pub struct PasswordResetToken {
pub:
	id         common.ID
	hash       []u8
	expires_at firebird.DateTime
	created_at firebird.DateTime
	deleted_at ?firebird.DateTime
}

pub fn (p PasswordResetToken) id() common.ID {
	return p.id
}

pub struct PasswordResetTokenCreateParams {
pub:
	id          common.ID
	user_id     ?common.ID
	customer_id ?common.ID
	hash        []u8
}

pub fn password_reset_token_create(mut tx firebird.ClientTransaction, p PasswordResetTokenCreateParams) ! {
	if (p.user_id != none && p.customer_id != none) || (p.user_id == none && p.customer_id == none) {
		return error('A password reset token must belong to either a user or a customer')
	}

	mut c := []string{len: 0, cap: 5}
	mut params := []firebird.Value{len: 0, cap: 5, init: firebird.Null{}}

	c << 'id'
	params << p.id.bytes()

	if user_id := p.user_id {
		c << 'user_id'
		params << user_id.bytes()
	}

	if customer_id := p.customer_id {
		c << 'customer_id'
		params << customer_id.bytes()
	}

	c << 'hash'
	params << p.hash

	tx.execute('INSERT INTO password_reset_token (${get_columns(c)}) VALUES (${get_placeholders(params)})',
		...params)!
}

pub fn password_reset_token_delete(mut tx firebird.ClientTransaction, token_id common.ID) ! {
	tx.execute('UPDATE password_reset_token SET deleted_at = CURRENT_TIMESTAMP WHERE id = ?',
		token_id.bytes())!
}

pub fn password_reset_token_delete_by_user(mut tx firebird.ClientTransaction, user_id common.ID) ! {
	tx.execute('UPDATE password_reset_token SET deleted_at = CURRENT_TIMESTAMP 
		WHERE user_id = ?
		AND deleted_at IS NULL',
		user_id.bytes())!
}

pub fn password_reset_token_delete_by_customer(mut tx firebird.ClientTransaction, customer_id common.ID) ! {
	tx.execute('UPDATE password_reset_token SET deleted_at = CURRENT_TIMESTAMP 
		WHERE customer_id = ?
		AND deleted_at IS NULL',
		customer_id.bytes())!
}

pub struct PasswordResetTokenUser {
	PasswordResetToken
pub:
	user_id common.ID
}

pub fn password_reset_token_user_get(mut tx firebird.ClientTransaction, user_id common.ID) !PasswordResetTokenUser {
	data := tx.execute('SELECT
		id,
		hash,
		expires_at,
		created_at,
		FROM password_reset_token
		WHERE deleted_at IS NULL
			AND expires_at > CURRENT_TIMESTAMP
			AND user_id = ?',
		user_id.bytes())!

	rows := data.rows()
	if rows.len == 0 {
		return NotFound{}
	}

	v := rows[0].values()
	id_bin, _ := v[0].get_array_u8()!
	hash, _ := v[1].get_array_u8()!
	expires_at, _ := v[2].get_date_time()!
	created_at, _ := v[3].get_date_time()!

	id := common.id_from_bytes(id_bin)!

	return PasswordResetTokenUser{
		id:         id
		hash:       hash
		expires_at: expires_at
		created_at: created_at
		deleted_at: none
		user_id:    user_id
	}
}

pub struct PasswordResetTokenCustomer {
	PasswordResetToken
pub:
	customer_id common.ID
}

pub fn password_reset_token_customer_get(
	mut tx firebird.ClientTransaction,
	customer_id common.ID) !PasswordResetTokenCustomer {
	data := tx.execute('SELECT
		id,
		password_hash,
		password_salt,
		password_details_id,
		expires_at,
		created_at,
		FROM password_reset_token
		WHERE deleted_at IS NULL
			AND expires_at > CURRENT_TIMESTAMP
			AND customer_id = ?',
		customer_id.bytes())!

	rows := data.rows()
	if rows.len == 0 {
		return NotFound{}
	}

	v := rows[0].values()
	id_bin, _ := v[0].get_array_u8()!
	hash, _ := v[1].get_array_u8()!
	expires_at, _ := v[2].get_date_time()!
	created_at, _ := v[3].get_date_time()!

	id := common.id_from_bytes(id_bin)!

	return PasswordResetTokenCustomer{
		id:          id
		hash:        hash
		expires_at:  expires_at
		created_at:  created_at
		deleted_at:  none
		customer_id: customer_id
	}
}
