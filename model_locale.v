module main

import einar_hjortdal.firebird

struct Locale {
	code string
}

fn parse_locale(v []firebird.Value) !Locale {
	code, _ := v[0].get_string()!

	return Locale{
		code: code
	}
}
