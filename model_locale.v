module main

import einar_hjortdal.firebird

struct Locale {
	id     string
	id_bin []u8
	code   string
}

fn parse_locale(v []firebird.Value) !Locale {
	id_bin, _ := v[0].get_array_u8()!
	code, _ := v[1].get_string()!

	id := id_bin_to_string(id_bin)!

	return Locale{
		id:     id
		id_bin: id_bin
		code:   code
	}
}
