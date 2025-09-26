module peony

fn test_zero_bool() {
	k := 'gzip'
	m := {
		k: ''
	}
	zb := zero_bool(m, k)
	assert zb.is_set
	assert zb.v
}
