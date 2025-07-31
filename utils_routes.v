module peony

fn option_id_string_to_id_bin(option_id_string ?string) ![]u8 {
	if id_string := option_id_string {
		return id_string_to_bin(id_string)!
	}
	return []u8{}
}

fn option_array_id_string_to_array_id_bin(option_array_id_string ?[]string) ![][]u8 {
	if array_id_string := option_array_id_string {
		mut array_id_bin := [][]u8{len: array_id_string.len}
		for i := 0; i < array_id_string.len; i++ {
			array_id_bin[i] = id_string_to_bin(array_id_string[i])!
		}
		return array_id_bin
	}
	return [][]u8{}
}

fn zero_id_string_to_id_bin(zero_id_string ZeroString) ![]u8 {
	if zero_id_string.is_set {
		return id_string_to_bin(zero_id_string.v)!
	}
	return []u8{}
}

fn zero_array_id_string_to_array_id_bin(zero_array_id_string ZeroArrayString) ![][]u8 {
	if zero_array_id_string.is_set {
		mut array_id_bin := [][]u8{len: zero_array_id_string.v.len}
		for i := 0; i < zero_array_id_string.v.len; i++ {
			array_id_bin[i] = id_string_to_bin(zero_array_id_string.v[i])!
		}
		return array_id_bin
	}
	return [][]u8{}
}
