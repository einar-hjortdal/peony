module main

import einar_hjortdal.luuid

fn id_string_to_bin(id_string string) ![]u8 {
	return luuid.to_bytes(id_string)
}

fn id_bin_to_string(id_bin []u8) !string {
	return luuid.from_bytes(id_bin)
}

struct ID {
	s string
	b []u8
}

fn id_from_bin(id_bin []u8) !ID {
	id_string := luuid.from_bytes(id_bin)!
	return ID{
		s: id_string
		b: id_bin
	}
}

fn id_from_string(id_string string) !ID {
	id_bin := luuid.to_bytes(id_string)!
	return ID{
		s: id_string
		b: id_bin
	}
}

fn new_id(mut g luuid.Generator) !ID {
	id_string := g.v1().to_upper()
	return id_from_string(id_string)
}

fn (id ID) string() string {
	return id.s
}

fn (id ID) bin() []u8 {
	return id.b
}

fn (mut app App) new_id() !ID {
	return new_id(mut app.luuid_generator)
}
