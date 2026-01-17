module peony

pub const min_fetch = i32(1)
pub const max_fetch = i32(250)

struct ZeroString {
	v      string
	is_set bool
}

// TODO change `v` to `value`
fn zero_string(m map[string]string, k string) ZeroString {
	if k in m {
		return ZeroString{
			v:      m[k]
			is_set: true
		}
	}
	return ZeroString{}
}

struct ZeroArrayString {
	v      []string
	is_set bool
}

fn zero_array_string(m map[string]string, k string) ZeroArrayString {
	s := zero_string(m, k)
	if s.is_set {
		return ZeroArrayString{
			v:      s.v.split(',')
			is_set: true
		}
	}
	return ZeroArrayString{}
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
		if s.v == '' {
			return ZeroBool{
				v:      true
				is_set: true
			}
		}

		return ZeroBool{
			v:      parse_bool(s.v)
			is_set: true
		}
	}
	return ZeroBool{}
}

fn hygienise_fetch_amount(zi32 ZeroI32) !i32 {
	if !zi32.is_set {
		return max_fetch
	}

	if zi32.v < 1 {
		return new_internal_error('Too few objects requested. Minimum ${min_fetch} must be requested',
			'requested ${zi32.v}')
	}

	if zi32.v > max_fetch {
		return new_internal_error('Too many objects requested. Maximum ${max_fetch} can be requested',
			'requested ${zi32.v}')
	}

	return zi32.v
}
