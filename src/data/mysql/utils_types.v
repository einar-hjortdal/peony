module mysql

pub fn bit_to_bool(bit string) bool {
	if bit == '1' {
		return true
	} else {
		return false
	}
}
