module peony

import arrays
import einar_hjortdal.firebird

struct Store {
	id                            string
	id_bin                        []u8
	created_at                    firebird.DateTime
	updated_at                    firebird.DateTime
	name                          string
	default_locale_id             string
	default_locale_id_bin         []u8
	default_region_id             string
	default_region_id_bin         []u8
	default_stock_location_id     string
	default_stock_location_id_bin []u8
	default_sales_channel_id      string
	default_sales_channel_id_bin  []u8
mut:
	locales []Locale
}

fn model_store_retrieve(mut tx firebird.Transaction) !Store {
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

	id := id_bin_to_string(id_bin)!
	default_locale_id := id_bin_to_string(default_locale_id_bin)!
	default_region_id := id_bin_to_string(default_region_id_bin)!
	default_stock_location_id := id_bin_to_string(default_stock_location_id_bin)!
	default_sales_channel_id := id_bin_to_string(default_sales_channel_id_bin)!

	return Store{
		id:                            id
		id_bin:                        id_bin
		created_at:                    created_at
		updated_at:                    updated_at
		name:                          name
		default_locale_id:             default_locale_id
		default_locale_id_bin:         default_locale_id_bin
		default_region_id:             default_region_id
		default_region_id_bin:         default_region_id_bin
		default_stock_location_id:     default_stock_location_id
		default_stock_location_id_bin: default_stock_location_id_bin
		default_sales_channel_id:      default_sales_channel_id
		default_sales_channel_id_bin:  default_sales_channel_id_bin
	}
}

fn model_store_locales_retrieve(mut tx firebird.Transaction) ![]Locale {
	data := tx.execute('SELECT id, code FROM locale l WHERE EXISTS (
		SELECT 1 FROM store_locales sl WHERE sl.locale_id = l.id)')!

	rows := data.rows()

	mut locales := []Locale{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()

		id_bin, _ := v[0].get_array_u8()!
		code, _ := v[1].get_string()!

		id := id_bin_to_string(id_bin)!

		locales[i] = Locale{
			id:     id
			id_bin: id_bin
			code:   code
		}
	}

	return locales
}

fn model_store_locales_update(mut tx firebird.Transaction, id_bin []u8, locale_ids_bin [][]u8) ! {
	s := 'SELECT
		CAST(? AS BINARY(16)) AS store_id,
		CAST(? AS BINARY(16)) AS locale_id
		FROM RDB\$DATABASE'
	mut src := ''
	mut params := []firebird.Value{len: locale_ids_bin.len * 2 + 2, init: firebird.Null{}}
	for i := 0; i < locale_ids_bin.len; i++ {
		src = appendln(src, s)
		params[i * 2] = id_bin
		params[i * 2 + 1] = locale_ids_bin[i]
		if i != locale_ids_bin.len - 1 {
			src = appendln(src, 'UNION ALL')
		}
	}

	query := 'MERGE INTO store_locales t
		USING (${src}) s (store_id, locale_id)
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
	params[params.len - 2] = id_bin
	params[params.len - 1] = id_bin
	tx.execute(query, ...params)!
}

fn model_store_update(mut tx firebird.Transaction, id_bin []u8, ph StoreUpdateRequestHygienised) ! {
	mut columns := []string{}
	mut params := []firebird.Value{}

	if name := ph.name {
		columns = arrays.concat(columns, 'name')
		params = arrays.concat(params, name)
	}

	if _ := ph.default_locale_id {
		columns = arrays.concat(columns, 'default_locale_id')
		params = arrays.concat(params, ph.default_locale_id_bin)
	}

	if _ := ph.default_region_id {
		columns = arrays.concat(columns, 'default_region_id')
		params = arrays.concat(params, ph.default_region_id_bin)
	}

	if _ := ph.default_stock_location_id {
		columns = arrays.concat(columns, 'default_stock_location_id')
		params = arrays.concat(params, ph.default_stock_location_id_bin)
	}

	if _ := ph.default_sales_channel_id {
		columns = arrays.concat(columns, 'default_sales_channel_id')
		params = arrays.concat(params, ph.default_sales_channel_id_bin)
	}

	params = arrays.concat(params, id_bin)
	tx.execute('UPDATE store SET ${get_set_columns_with_updated_at(columns)} WHERE id = ?',
		...params)!
}
