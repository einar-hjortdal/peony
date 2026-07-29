module peony

import crypto.argon2
import crypto.blake2b
import crypto.rand
import crypto.subtle
import encoding.base64
import json2
import internal.errors

const argon2id_name = 'argon2id'
const argon2id_version = i32(argon2.version)
const argon2id_time = 3
const argon2id_memory = 1 << 16
const argon2id_threads = 4
const argon2id_key_length = 64
const argon2id_salt_length = 16
const password_reset_token_size = 32
const blake2b_hash_size = 32

// When retrieving a password, retrieve the params from the database too.
// When inserting a new password, also insert these parameters in the password_details table. To prevent duplicates in that table, we encode and hash the parameters and index the hash.

interface PasswordHash {
	function_name() string
	verify_password(password string) !
	encode_parameters() (string, []u8)
}

struct Argon2idParameters {
	version i32
	time    i32
	memory  i32
	threads i32
}

struct Argon2idHash {
	hash       []u8
	salt       []u8
	parameters Argon2idParameters
}

fn hash_password(password string) !Argon2idHash {
	salt := rand.bytes(argon2id_salt_length)!
	return Argon2idHash{
		salt:       salt
		hash:       argon2.id_key(password.bytes(), salt, argon2id_time, argon2id_memory,
			argon2id_threads, argon2id_key_length)!
		parameters: Argon2idParameters{
			version: argon2id_version
			time:    argon2id_time
			memory:  argon2id_memory
			threads: argon2id_threads
		}
	}
}

fn (h Argon2idHash) function_name() string {
	return argon2id_name
}

fn (h Argon2idHash) verify_password(password string) ! {
	version := h.parameters.version
	if version != argon2id_version {
		return error('unsupported Argon2id version: supported ${argon2id_version}, got ${version}')
	}

	new_hash := argon2.id_key(password.bytes(), h.salt, u32(h.parameters.time),
		u32(h.parameters.memory), u8(h.parameters.threads), u32(h.hash.len))!

	if new_hash != h.hash {
		return error('password does not match')
	}
}

// returns json-encoded parameters together with the unique hash
fn (h Argon2idHash) encode_parameters() (string, []u8) {
	encoded := json2.encode(h.parameters, escape_unicode: true)
	hash := blake2b.sum256(encoded.bytes())
	return encoded, hash
}

fn decode_argon2id_parameters(s string) !Argon2idParameters {
	res := json2.decode[Argon2idParameters](s) or {
		return errors.internal('Failed to decode Argon2idParameters', err.msg())
	}
	return res
}

fn verify_password(password string, password_hash []u8, password_salt []u8, function_name string, parameters_json string) ! {
	match function_name {
		argon2id_name {
			parameters := decode_argon2id_parameters(parameters_json)!

			argon2id_hash := Argon2idHash{
				hash:       password_hash
				salt:       password_salt
				parameters: parameters
			}

			argon2id_hash.verify_password(password) or { return errors.login() }
		}
		else {
			return errors.internal('Unsupported password hashing algorithm',
				'decoded function name: `${function_name}`')
		}
	}
}

// We generate 32 cryptographically secure random bytes, URL-safe base64-encode them to send over the network to the user, and store only a fast keyed hash of the raw bytes. Verification is a constant-time compare of the recomputed hash. This is appropriate for high-entropy tokens and avoids the cost of computationally expensive password hashes
fn hash_password_reset_token(secret string, token []u8) ![]u8 {
	digest := blake2b.new_digest(blake2b_hash_size, secret.bytes())!
	digest.write(token)!
	hash := digest.checksum()
	return hash
}

// returns url-encoded token and hash
fn new_password_reset_token(secret string) !(string, []u8) {
	token := rand.bytes(password_reset_token_size)!
	encoded := base64.url_encode(token)
	hash := hash_password_reset_token(secret, token)!
	return encoded, hash
}

// verifies if the provided url-encoded token matches the stored hash
fn verify_password_reset_token(secret string, stored_hash []u8, encoded string) ! {
	if stored_hash.len != blake2b_hash_size {
		return error('stored hash has unexpected size')
	}

	token := base64.url_decode(encoded)
	hash := hash_password_reset_token(secret, token)!
	if subtle.constant_time_compare(hash, stored_hash) != 1 {
		return error('no match')
	}
}
