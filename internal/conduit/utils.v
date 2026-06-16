module conduit

import net.http
import einar_hjortdal.luuid
import common

pub const error_database_data_malformed = 'Data retrieved from database is malformed'

const min_fetch = common.min_fetch
const max_fetch = common.max_fetch
const offset_default = common.offset_default
const order_asc = common.order_asc
const order_desc = common.order_desc
const order_default = common.order_default

pub type ID = common.ID

pub fn new_id(mut g luuid.Generator) ID {
	return common.new_id(mut g)
}

pub fn id_from_string(s string) !ID {
	return common.id_from_string(s)
}

fn make_identifiable_map[T](identifiables []T) (map[string]T, []ID) {
	mut map_res := map[string]T{}
	mut arr_res := []ID{len: identifiables.len}
	for i := 0; i < identifiables.len; i++ {
		identifiable := identifiables[i]
		id := identifiable.id()
		map_res[id.string()] = identifiable
		arr_res[i] = id
	}
	return map_res, arr_res
}
