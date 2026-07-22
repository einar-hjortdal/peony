module peony

import crypto.argon2
import crypto.blake2b
import crypto.rand
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

// Storing password hashes in the database
// Many projects use the PHC string format (https://github.com/P-H-C/phc-string-format) to store password hashes. For this application, it isn't obvious that storing the full PHC token per user is necessary:
//   - Algorithm name, version, and parameters are unlikely to change often and would be duplicated across many rows.
//   - Portability is not important for this application.
// An alternative is to store the raw binary values and reference shared parameters:
//   - password_hash      BINARY(64)   // 64 bytes raw derived key
//   - password_salt      BINARY(16)   // 16 bytes per-user salt
//   - password_params_id BINARY(16)   // 16 bytes referencing params table
// That layout is about 96 bytes per user, plus a single params row (~80 bytes) stored once. Amortized across any realistic user base, the shared params cost is negligible, so this approach can save ~124 bytes per user compared to storing the full PHC string. It is slightly more complex though.

// When retrieving a password, retrieve the params from the database.
// When inserting a new password, use the defined consts for parameters. These params may already be stored in the database: first verify if they exist and what their id is. If they already are set, use the existing id otherwise create a new record and then use that id.

interface PasswordHash {
	function_name() string
	verify_password(password string) !
	encode_parameters() !(string, []u8)
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
fn (h Argon2idHash) encode_parameters() !(string, []u8) {
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

fn new_password_reset_token() !string {
	b := rand.bytes(16)!
	return base64.url_encode(b)
}

fn decode_password_reset_token(s string) []u8 {
	return base64.url_decode(s)
}
