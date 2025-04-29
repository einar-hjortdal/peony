module main

import os
import strings
import einar_hjortdal.luuid

const to_replace = 'REPLACE_WITH_LUUID'
const new_line = '\n'

fn wrap_in_quotes(s string) string {
	return '"${s}"'
}

fn main() {
	mut g := luuid.new_generator()
	lines := os.read_lines('./seed-schema-source.sql')!
	mut res := strings.new_builder(0)
	for i := 0; i < lines.len; i++ {
		id := wrap_in_quotes(g.v1())
		line := lines[i].replace(to_replace, id) + new_line
		res.write_string(line)
	}
	os.write_file('./seed-schema.sql', res.str())!
}
