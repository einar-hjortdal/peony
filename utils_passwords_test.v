module peony

import rand

fn test_password_reset_token() {
	secret := rand.ascii(32)
	encoded, hash := new_password_reset_token(secret)!
	verify_password_reset_token(secret, hash, encoded)!
}
