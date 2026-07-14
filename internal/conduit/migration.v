module conduit

import einar_hjortdal.firebird
import record
import internal.errors
import internal.common

pub fn migration_create(mut tx firebird.ClientTransaction, migration_id common.ID, name string) ! {
	record.migration_create(mut tx, migration_id, name) or {
		return errors.internal('Failed to create migration', err.msg())
	}
}

pub fn migration_list(mut tx firebird.ClientTransaction) ![]Migration {
	migrations := record.migration_retrieve(mut tx) or {
		return errors.internal('Failed to retrieve migration', err.msg())
	}
	return migrations
}
