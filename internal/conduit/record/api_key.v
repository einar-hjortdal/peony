module record

import einar_hjortdal.firebird
import arrays
import internal.common

pub struct APIKey {
pub:
	id               common.ID
	created_at       firebird.DateTime
	updated_at       firebird.DateTime
	deleted_at       ?firebird.DateTime
	name             string
	sales_channel_id common.ID
}

pub struct APIKeyCreateParams {
pub:
	id               common.ID
	name             string
	sales_channel_id common.ID
}

pub fn api_key_create(mut tx firebird.ClientTransaction, p APIKeyCreateParams) ! {
	tx.execute('INSERT INTO api_key (id, name, sales_channel_id) VALUES (?, ?, ?)', p.id.bytes(),
		p.name, p.sales_channel_id.bytes())!
}

pub struct APIKeyRetrieveParams {
pub:
	ids               ?[]common.ID
	sales_channel_ids ?[]common.ID
	with_deleted      bool
	offset            i32
	fetch             i32
	order             string
}

pub fn api_key_retrieve_conditions(p APIKeyRetrieveParams) (string, []firebird.Value) {
	mut conditions := []string{}
	mut params := []firebird.Value{}

	if ids := p.ids {
		conditions = arrays.concat(conditions, 'id IN (${get_placeholders(ids)})')
		params = arrays.concat(params, ...ids_bytes(ids))
	}

	if sales_channel_ids := p.sales_channel_ids {
		conditions = arrays.concat(conditions,
			'sales_channel_id IN (${get_placeholders(sales_channel_ids)})')
		params = arrays.concat(params, ...ids_bytes(sales_channel_ids))
	}

	if !p.with_deleted {
		conditions = arrays.concat(conditions, 'deleted_at is NULL')
	}

	return get_where_conditions(conditions), params
}

pub fn api_key_retrieve_count(mut tx firebird.ClientTransaction, p APIKeyRetrieveParams) !i64 {
	conditions, params := api_key_retrieve_conditions(p)
	data := tx.execute('SELECT COUNT(*) FROM api_key ${conditions}', ...params)!
	rows := data.rows()
	values := rows[0].values() // should always return one row
	count, _ := values[0].get_i64()! // should always return one column
	return count
}

pub fn api_key_retrieve(mut tx firebird.ClientTransaction, p APIKeyRetrieveParams) ![]APIKey {
	conditions, mut params := api_key_retrieve_conditions(p)

	mut sorting := 'ORDER BY created_at ${p.order}
		OFFSET ? ROWS
		FETCH NEXT ? ROWS ONLY'
	params = arrays.concat(params, p.offset, p.fetch)

	query := 'SELECT
		id,
		created_at,
		updated_at,
		deleted_at,
		name,
		sales_channel_id
		FROM api_key
		${conditions}
		${sorting}'

	data := tx.execute(query, ...params)!

	rows := data.rows()

	mut api_keys := []APIKey{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()
		id_bin, _ := v[0].get_array_u8()!
		created_at, _ := v[1].get_date_time()!
		updated_at, _ := v[2].get_date_time()!
		deleted_at := v[3].get_null_date_time()!
		name, _ := v[4].get_string()!
		sales_channel_id_bin, _ := v[5].get_array_u8()!

		id := common.id_from_bytes(id_bin)!
		sales_channel_id := common.id_from_bytes(sales_channel_id_bin)!

		api_keys[i] = APIKey{
			id:               id
			created_at:       created_at
			updated_at:       updated_at
			deleted_at:       deleted_at.none_value()
			name:             name
			sales_channel_id: sales_channel_id
		}
	}
	return api_keys
}

pub struct APIKeyUpdateParams {
pub:
	id               common.ID
	name             ?string
	sales_channel_id ?common.ID
}

pub fn api_key_update(mut tx firebird.ClientTransaction, p APIKeyUpdateParams) ! {
	mut columns := []string{}
	mut params := []firebird.Value{}

	if name := p.name {
		columns = arrays.concat(columns, 'name')
		params = arrays.concat(params, name)
	}

	if sales_channel_id := p.sales_channel_id {
		columns = arrays.concat(columns, 'sales_channel_id')
		params = arrays.concat(params, sales_channel_id.bytes())
	}

	query := 'UPDATE api_key ${get_set_columns_with_updated_at(columns)} WHERE id = ?'
	params = arrays.concat(params, p.id.bytes())
	tx.execute(query, ...params)!
}

pub fn api_key_delete(mut tx firebird.ClientTransaction, api_key common.ID) ! {
	tx.execute('UPDATE api_key SET deleted_at = CURRENT_TIMESTAMP WHERE id = ?', api_key.bytes())!
}
