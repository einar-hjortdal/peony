module record

import arrays
import einar_hjortdal.firebird
import internal.common

pub struct Store {
pub:
	id                        common.ID
	created_at                firebird.DateTime
	updated_at                firebird.DateTime
	name                      string
	default_locale_id         common.ID
	default_region_id         common.ID
	default_stock_location_id common.ID
	default_sales_channel_id  common.ID
pub mut:
	locales []Locale
}

pub fn (s Store) id() common.ID {
	return s.id
}

pub fn store_retrieve(mut tx firebird.ClientTransaction) !Store {
	store_data := tx.execute('SELECT
		id,
		created_at,
		updated_at,
		name,
		default_locale_id,
		default_region_id,
		default_stock_location_id,
		default_sales_channel_id
		FROM store')!

	store_rows := store_data.rows()

	if store_rows.len == 0 {
		return error('No entries in table store')
	}

	v := store_rows[0].values()

	id_bin, _ := v[0].get_array_u8()!
	created_at, _ := v[1].get_date_time()!
	updated_at, _ := v[2].get_date_time()!
	name, _ := v[3].get_string()!
	default_locale_id_bin, _ := v[4].get_array_u8()!
	default_region_id_bin, _ := v[5].get_array_u8()!
	default_stock_location_id_bin, _ := v[6].get_array_u8()!
	default_sales_channel_id_bin, _ := v[7].get_array_u8()!

	id := common.id_from_bytes(id_bin)!
	default_locale_id := common.id_from_bytes(default_locale_id_bin)!
	default_region_id := common.id_from_bytes(default_region_id_bin)!
	default_stock_location_id := common.id_from_bytes(default_stock_location_id_bin)!
	default_sales_channel_id := common.id_from_bytes(default_sales_channel_id_bin)!

	return Store{
		id:                        id
		created_at:                created_at
		updated_at:                updated_at
		name:                      name
		default_locale_id:         default_locale_id
		default_region_id:         default_region_id
		default_stock_location_id: default_stock_location_id
		default_sales_channel_id:  default_sales_channel_id
	}
}

pub fn store_locales_retrieve(mut tx firebird.ClientTransaction) ![]Locale {
	data := tx.execute('SELECT id, code FROM locale l WHERE EXISTS (
		SELECT 1 FROM store_locales sl WHERE sl.locale_id = l.id)')!

	rows := data.rows()

	mut locales := []Locale{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()

		id_bin, _ := v[0].get_array_u8()!
		code, _ := v[1].get_string()!

		id := common.id_from_bytes(id_bin)!

		locales[i] = Locale{
			id:   id
			code: code
		}
	}

	return locales
}

pub fn store_locales_update(mut tx firebird.ClientTransaction, store_id common.ID, locale_ids []common.ID) ! {
	mut src := []string{len: locale_ids.len}
	mut params := []firebird.Value{len: locale_ids.len * 2 + 2, init: firebird.Null{}}
	for i := 0; i < locale_ids.len; i++ {
		src[i] = 'SELECT
			CAST(? AS BINARY(16)) AS store_id,
			CAST(? AS BINARY(16)) AS locale_id
			FROM RDB\$DATABASE'
		params[i * 2] = store_id.bytes()
		params[i * 2 + 1] = locale_ids[i].bytes()
	}

	query := 'MERGE INTO store_locales t
		USING (${get_merge_source(src)}) s (store_id, locale_id)
		ON (t.store_id = s.store_id AND t.locale_id = s.locale_id)
		WHEN NOT MATCHED THEN
			INSERT (store_id, locale_id)
			VALUES (s.store_id, s.locale_id)
		WHEN NOT MATCHED BY SOURCE
			AND t.store_id = ?
			AND t.locale_id <> (
				SELECT default_locale_id
				FROM store
				WHERE id = ?)
			THEN DELETE'
	params[params.len - 2] = store_id.bytes()
	params[params.len - 1] = store_id.bytes()
	tx.execute(query, ...params)!
}

pub struct StoreUpdateParams {
pub:
	name                      ?string
	default_locale_id         ?common.ID
	default_region_id         ?common.ID
	default_stock_location_id ?common.ID
	default_sales_channel_id  ?common.ID
}

pub fn store_update(mut tx firebird.ClientTransaction, store_id common.ID, p StoreUpdateParams) ! {
	mut columns := []string{}
	mut params := []firebird.Value{}

	if name := p.name {
		columns = arrays.concat(columns, 'name')
		params = arrays.concat(params, name)
	}

	if default_locale_id := p.default_locale_id {
		columns = arrays.concat(columns, 'default_locale_id')
		params = arrays.concat(params, default_locale_id.bytes())
	}

	if default_region_id := p.default_region_id {
		columns = arrays.concat(columns, 'default_region_id')
		params = arrays.concat(params, default_region_id.bytes())
	}

	if default_stock_location_id := p.default_stock_location_id {
		columns = arrays.concat(columns, 'default_stock_location_id')
		params = arrays.concat(params, default_stock_location_id.bytes())
	}

	if default_sales_channel_id := p.default_sales_channel_id {
		columns = arrays.concat(columns, 'default_sales_channel_id')
		params = arrays.concat(params, default_sales_channel_id.bytes())
	}

	params = arrays.concat(params, store_id.bytes())
	tx.execute('UPDATE store SET ${get_set_columns_with_updated_at(columns)} WHERE id = ?',
		...params)!
}
