module conduit

import einar_hjortdal.firebird
import record

pub type Migration = record.Migration

pub fn migration_create(mut tx firebird.Transaction, migration_id ID, name string) ! {
	record.migration_create(mut tx, migration_id, name) or {
		return new_error_internal('Failed to create migration', err.msg())
	}
}

pub fn migration_list(mut tx firebird.Transaction) ![]Migration {
	migrations := record.migration_retrieve(mut tx) or {
		return new_error_internal('Failed to retrieve migration', err.msg())
	}
	return migrations
}

