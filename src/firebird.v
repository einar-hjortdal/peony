module main

// import arrays
// import log
// import os
// import eianr_hjortdal.luuid
import einar_hjortdal.firebird

fn database_is_ready(mut conn firebird.Connection) bool {
	// assume the database is ready if get_store_data does not fail
	if _ := get_store_data(mut conn) {
		return true
	} else {
		return false
	}
}

fn seed_db(mut conn firebird.Connection) ! {}

fn prepare_db(mut conn firebird.Connection) ! {
	if database_is_ready(mut conn) {
		return
	}
	seed_db(mut conn)!
}
