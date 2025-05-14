module main

import einar_hjortdal.firebird
import einar_hjortdal.luuid

fn (mut app App) start_transaction() !&firebird.Transaction {
	return app.fb.start_transaction(firebird.isolation_level_read_commited)!
}

fn (mut app App) new_id() !(string, []u8) {
	id_string := app.luuid_generator.v1().to_upper()
	id_bin := luuid.to_bytes(id_string)!
	return id_string, id_bin
}
