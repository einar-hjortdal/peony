module main

import crypto.rand
import crypto.scrypt

const scrypt_n = 1 << 16 // 2 raised to the power of 16
const scrypt_r = 8
const scrypt_p = 2
const scrypt_salt_length = 32
const scrypt_hash_length = 64

// returns salt and hash
fn hash_password(pwd string) !([]u8, []u8) {
	password_salt := rand.bytes(scrypt_salt_length)!
	password_hash := scrypt.scrypt(pwd.bytes(), password_salt, scrypt_n, scrypt_r, scrypt_p,
		scrypt_hash_length)!
	return password_salt, password_hash
}

fn verify_password(pwd string, password_hash []u8, password_salt []u8) ! {
	new_hash := scrypt.scrypt(pwd.bytes(), password_salt, scrypt_n, scrypt_r, scrypt_p,
		scrypt_hash_length)!
	if password_hash != new_hash {
		return error(format_error_message('Bad password'))
	}
}
