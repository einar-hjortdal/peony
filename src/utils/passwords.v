module utils

// vlib
import crypto.bcrypt
import crypto.sha256

/*
* Passwords that contain less than 72 bytes of data can be passed to bcrypt directly, passwords that
* contain more than 72 bytes of data could either be truncated or pre-hashed.
*
* Truncating the password means that bcrypt receives 72 bytes of data.
* Pre-hashing with SHA256 produces 32 bytes of data that can be then passed to bcrypt.
* This is why many suggest that pre-hashing with SHA256 reduces entropy.
*
* While a potential attacker could guess a pre-hashed password more easily than a truncated password,
* this guess cannot be used to authenticate as the user.
* Any password string given to the endpoint will be hashed with SHA256 and then bcrypt. The attacker
* cannot skip the SHA256 hashing step.
*
* Because of this, the entropy that matters is the entropy of the user-provided password, not of the
* intermediate hash. Truncating a password to 72 bytes reduces the entropy more than not truncating
* it.
*
* The only knwon vulnerability is related to third-party database leaks. This must satisfy the following
* conditions:
* - The leaked database contains SHA256-hashed passwords.
* - The leaked SHA256-hashed password must have been the same as the one used in this application.
* - The user email was also leaked, or can be guessed.
* The leaked re-used SHA256-hashed password can be derived. At this point the attacker can provide the
* derived password to authenticate as the victim.
*
* The risk of this happening is relatively low, it can be mitigated by adding salt to the pre-hash.
*
* To protect the application from potential damage caused by compromised privileged users, additional
* protection mechanisms should be employed. peony recommends to put the /admin endpoints behind a firewall,
* making these endpoints only accessible through an SSH tunnel employing public key authentication.
* Customers do not need this level of protection as they pose little potential damage to the application.
*/

// validate_password should always be executed before new_password_hash.
pub fn validate_password(password string) ! {
	if password.runes().len < 10 {
		return error('password must have at least 10 characters')
	}
	// prevent long-password denial of service attacks
	if password.runes().len > 1024 {
		return error('password cannot be longer than 1024 characters')
	}
	// TODO use regex to enforce some specific characters to be included
}

// TODO add salt
// TODO update database to store longer hashes (add salt length)
pub fn new_password_hash(password string) !string {
	return bcrypt.generate_from_password(pre_hash(password), bcrypt.default_cost)!
}

pub fn verify_password(password string, hashed_password string) ! {
	bcrypt.compare_hash_and_password(pre_hash(password), hashed_password.bytes())!
}

fn pre_hash(password string) []u8 {
	return sha256.sum(password.bytes())
}

// TODO convert string to hex and
// store as BINARY(40) instead of VARCHAR(60), save 20 bytes per user
// TODO update database to use BINARY(40) and queries to use HEX()/UNHEX()
