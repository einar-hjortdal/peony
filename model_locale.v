module main

import einar_hjortdal.firebird

struct Locale {
	locale_code string
}

fn parse_locale(v []firebird.Value) !Locale {
	locale_code, _ := v[0].get_string()!

	return Locale{
		locale_code: locale_code
	}
}
