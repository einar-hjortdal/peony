module record

import einar_hjortdal.firebird
import internal.common

pub struct NotificationProvider {
pub:
	id           common.ID
	name         string
	is_installed bool
}

pub fn notification_provider_retrieve(mut tx firebird.ClientTransaction) ![]NotificationProvider {
	data := tx.execute('SELECT id, name, is_installed FROM notification_provider')!
	rows := data.rows()
	mut res := []NotificationProvider{len: 0, cap: rows.len}
	for _, row in rows {
		v := row.values()
		id_bin, _ := v[0].get_array_u8()!
		name, _ := v[1].get_string()!
		is_installed, _ := v[2].get_bool()!

		id := common.id_from_bytes(id_bin)!

		res << NotificationProvider{
			id:           id
			name:         name
			is_installed: is_installed
		}
	}
	return res
}

pub struct NotificationProviderCreateParams {
pub:
	id           common.ID
	name         string
	is_installed bool
}

pub fn notification_provider_create(mut tx firebird.ClientTransaction, p []NotificationProviderCreateParams) ! {
	mut src := []string{len: 0, cap: p.len}
	mut params := []firebird.Value{len: 0, cap: p.len, init: common.Empty{}}
	for _, v in p {
		src << 'SELECT
			CAST(?) AS BINARY(16) AS id,
			CAST(?) AS VARCHAR(63) AS name,
			CAST(?) AS BOOLEAN AS is_installed
			FROM RDB\$DATABASE'

		params << v.id.bytes()
		params << v.name
		params << v.is_installed
	}

	tx.execute('INSERT INTO notification_provider (id, name, is_installed) ${get_merge_source(src)}',
		...params)!
}

pub fn notification_provider_install(mut tx firebird.ClientTransaction, ids []common.ID) ! {
	tx.execute('UPDATE notification_provider SET 
		is_installed = true,
		updated_at = CURRENT_TIMESTAMP
		WHERE id IN (${get_placeholders(ids)})',
		...ids_bytes(ids))!
}

pub fn notification_provider_uninstall(mut tx firebird.ClientTransaction, ids []common.ID) ! {
	tx.execute('UPDATE notification_provider SET 
		is_installed = false,
		updated_at = CURRENT_TIMESTAMP
		WHERE id IN (${get_placeholders(ids)})',
		...ids_bytes(ids))!
}

pub fn notification_provider_uninstall_all(mut tx firebird.ClientTransaction) ! {
	tx.execute('UPDATE notification_provider SET 
		is_installed = false,
		updated_at = CURRENT_TIMESTAMP
		WHERE is_installed = true')!
}

pub struct NotificationChannel {
pub:
	id          common.ID
	name        string
	provider_id ?common.ID
}

pub fn notification_channel_retrieve(mut tx firebird.ClientTransaction) ![]NotificationChannel {
	data := tx.execute('SELECT id, name, provider_id FROM notification_channel')!
	rows := data.rows()
	mut res := []NotificationChannel{len: 0, cap: rows.len}
	for _, row in rows {
		v := row.values()
		id_bin, _ := v[0].get_array_u8()!
		name, _ := v[1].get_string()!
		provider_id_bin := v[2].get_null_array_u8()!

		id := common.id_from_bytes(id_bin)!

		mut provider_id := ?common.ID(none)
		if !provider_id_bin.is_null() {
			provider_id = common.id_from_bytes(provider_id_bin.value())!
		}

		res << NotificationChannel{
			id:          id
			name:        name
			provider_id: provider_id
		}
	}
	return res
}

pub struct NotificationChannelCreateParams {
pub:
	id          common.ID
	name        string
	provider_id common.ID
}

pub fn notification_channel_create(mut tx firebird.ClientTransaction, p []NotificationChannelCreateParams) ! {
	mut src := []string{len: 0, cap: p.len}
	mut params := []firebird.Value{len: 0, cap: p.len, init: common.Empty{}}
	for _, v in p {
		src << 'SELECT
			CAST(?) AS BINARY(16) AS id,
			CAST(?) AS VARCHAR(63) AS name,
			CAST(?) AS BINARY(16) AS provider_id
			FROM RDB\$DATABASE'

		params << v.id.bytes()
		params << v.name
		params << v.provider_id.bytes()
	}

	tx.execute('INSERT INTO notification_channel (id, name, provider_id) ${get_merge_source(src)}',
		...params)!
}

pub struct NotificationChannelUpdateParams {
pub:
	id          common.ID
	provider_id common.ID
}

pub fn notification_channel_update(mut tx firebird.ClientTransaction, p []NotificationChannelUpdateParams) ! {
	mut src := []string{len: 0, cap: p.len}
	mut params := []firebird.Value{len: 0, cap: p.len, init: common.Empty{}}
	for _, v in p {
		src << 'SELECT
			CAST(?) AS BINARY(16) AS id,
			CAST(?) AS BINARY(16) AS provider_id
			FROM RDB\$DATABASE'

		params << v.id.bytes()
		params << v.provider_id.bytes()
	}

	tx.execute('MERGE INTO notification_channel t
		USING (${get_merge_source(src)}) s
		ON s.id = t.id
		WHEN MATCHED THEN UPDATE
			SET 
				t.provider_id = s.provider_id
				t.updated_at = CURRENT_TIMESTAMP',
		...params)!
}

pub fn notification_channel_disable_unserved(mut tx firebird.ClientTransaction) ! {
	tx.execute('UPDATE notification_channel nc
		SET
			nc.provider_id = NULL
			nc.updated_at = CURRENT_TIMESTAMP
		WHERE EXISTS (
			SELECT 1 FROM notification_provider np
			WHERE np.id = nc.provider_id
			AND np.is_installed = false
		)')!
}
