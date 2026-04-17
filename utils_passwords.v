module peony

import crypto.argon2
import crypto.blake2b
import crypto.rand
import json

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
// With today's default parameters the PHC token is roughly 220 bytes per user (~140 bytes for the token header + ~80 bytes for salt+hash). An alternative is to store the raw binary values and reference shared parameters:
//   - password_hash      BINARY(64)   // 64 bytes raw derived key
//   - password_salt      BINARY(16)   // 16 bytes per-user salt
//   - password_params_id BINARY(16)   // 16 bytes referencing params table
// That layout is about 96 bytes per user, plus a single params row (~80 bytes) stored once. Amortized across any realistic user base, the shared params cost is negligible, so this approach can save ~124 bytes per user compared to storing the full PHC string.
// This is slightly more complex, but it may be worth it at scale for the storage and I/O savings.

// When retrieving a password, retrieve the params from the database.
// When inserting a new password, use the defined consts for parameters. These params may already be stored in the database: first verify if they exist and what their id is. If they already are set, use the existing id otherwise create a new record and then use that id.

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

struct PasswordDetails {
	function_name string
	parameters    string
}

// returns encoded parameters together with the unique hash
fn (p Argon2idParameters) encode() !(string, []u8) {
	encoded := json.encode(PasswordDetails{
		function_name: argon2id_name
		parameters:    json.encode(p)
	})
	hash := blake2b.sum256(encoded.bytes())
	return encoded, hash
}

fn (p PasswordDetails) get_argon2id_parameters() !Argon2idParameters {
	return json.decode(Argon2idParameters, p.parameters)
}
