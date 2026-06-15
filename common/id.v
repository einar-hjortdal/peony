module common

import einar_hjortdal.luuid

pub interface Identifiable {
	id() ID
}

pub struct ID {
	s string
	b []u8
}

pub fn new_id(mut g luuid.Generator) ID {
	s := g.v1().to_upper()
	return ID{
		s: s
		b: luuid.to_bytes(s) or { panic(err) } // should never panic
	}
}

// detects if the ID is its zero value
pub fn (id ID) is_zero() bool {
	return id.s == '' && id.b.len == 0
}

pub fn (id ID) string() string {
	return id.s
}

pub fn (id ID) bytes() []u8 {
	return id.b
}

pub fn id_from_string(s string) !ID {
	return ID{
		s: s
		b: luuid.to_bytes(s)!
	}
}

pub fn id_from_bytes(b []u8) !ID {
	return ID{
		s: luuid.from_bytes(b)!
		b: b
	}
}
