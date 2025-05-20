module main

struct ZeroString {
	v      string
	is_set bool
}

fn zero_string(m map[string]string, k string) ZeroString {
	if k in m {
		return ZeroString{
			v:      m[k]
			is_set: true
		}
	}
	return ZeroString{}
}

struct ZeroI32 {
	v      i32
	is_set bool
}

fn zero_i32(m map[string]string, k string) ZeroI32 {
	s := zero_string(m, k)
	if s.is_set {
		return ZeroI32{
			v:      s.v.i32()
			is_set: true
		}
	}
	return ZeroI32{}
}

struct ZeroBool {
	v      bool
	is_set bool
}

fn zero_bool(m map[string]string, k string) ZeroBool {
	s := zero_string(m, k)
	if s.is_set {
		return ZeroBool{
			v:      parse_bool(s.v)
			is_set: true
		}
	}
	return ZeroBool{}
}
