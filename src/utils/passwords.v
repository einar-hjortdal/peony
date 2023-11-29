module utils

// vlib
import crypto.bcrypt

// validate_password should always be executed before new_password_hash.
pub fn validate_password(password string) ! {
	if password.runes().len < 10 {
		return error('password must have at least 10 characters')
	}
	// limit passwords to 72 bytes (max bcrypt can handle)
	if password.len > 72 {
		return error('password cannot be larger than 72 bytes')
	}
	// TODO use regex to enforce some specific characters to be included
}

// new_password_hash returns a binary string of the
pub fn new_password_hash(password string) !string {
	return bcrypt.generate_from_password(password.bytes(), bcrypt.default_cost)!
}

pub fn verify_password(password string, hashed_password string) ! {
	bcrypt.compare_hash_and_password(password.bytes(), hashed_password.bytes())!
}
