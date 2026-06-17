module conduit

import einar_hjortdal.luuid
import internal.common

pub const error_database_data_malformed = 'Data retrieved from database is malformed'

const min_fetch = common.min_fetch
const max_fetch = common.max_fetch
const offset_default = common.offset_default
const order_asc = common.order_asc
const order_desc = common.order_desc
const order_default = common.order_default

const role_admin = common.role_admin
const role_member = common.role_member
const role_developer = common.role_developer
const role_author = common.role_author
const role_contributor = common.role_contributor

pub type ID = common.ID

pub fn new_id(mut g luuid.Generator) ID {
	return common.new_id(mut g)
}

pub fn id_from_string(s string) !ID {
	return common.id_from_string(s)
}
