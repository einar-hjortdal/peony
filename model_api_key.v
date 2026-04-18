module peony

import einar_hjortdal.firebird

struct APIKey {
	id               ID
	created_at       firebird.DateTime
	updated_at       firebird.DateTime
	deleted_at       firebird.NullDateTime
	name             string
	sales_channel_id ID
}

fn api_key_create(mut tx firebird.Transaction, api_key ID, name string, sales_channel_id ID) ! {
	tx.execute('INSERT INTO api_key (id, name, sales_channel_id) VALUES (?, ?, ?)',
		api_key.bytes(), name, sales_channel_id.bytes())!
}

fn api_key_get(mut tx firebird.Transaction, api_key ID) !APIKey {
	data := tx.execute('SELECT FROM api_key (id, created_at, updated_at, deleted_at, name, sales_channel_id)
    WHERE id = ?')!
	rows := data.rows()
	if rows.len == 0 {
		return error('api_key not found')
	}

	v := rows[0].values()
	id_bin, _ := v[0].get_array_u8()!
	created_at, _ := v[1].get_date_time()!
	updated_at, _ := v[2].get_date_time()!
	deleted_at := v[3].get_null_date_time()!
	name, _ := v[4].get_string()!
	sales_channel_id_bin, _ := v[5].get_array_u8()!

	id := id_from_bytes(id_bin)!
	sales_channel_id := id_from_bytes(sales_channel_id_bin)!

	return APIKey{
		id:               id
		created_at:       created_at
		updated_at:       updated_at
		deleted_at:       deleted_at
		name:             name
		sales_channel_id: sales_channel_id
	}
}

struct APIKeyUpdateParams {
	name             string
	sales_channel_id ID
}

fn api_key_update(mut tx firebird.Transaction, api_key ID, p APIKeyUpdateParams) ! {
	columns := ['name', 'sales_channel_id']
	params := [firebird.Value(p.name), p.sales_channel_id.bytes(),
		api_key.bytes()]
	query := 'UPDATE api_key ${get_set_columns_with_updated_at(columns)} WHERE id = ?'
	tx.execute(query, ...params)!
}

fn api_key_delete(mut tx firebird.Transaction, api_key ID) ! {
	tx.execute('UPDATE api_key SET deleted_at = CURRENT_TIMESTAMP WHERE id = ?', api_key.bytes())!
}
