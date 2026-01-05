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
	default_currency_code         string
mut:
	locales    []Locale
	currencies []Currency
}

fn model_store_retrieve(mut tx firebird.Transaction) !Store {
	store_data := tx.execute('SELECT
		s.id,
		s.created_at,
		s.updated_at,
		s.name,
		s.default_locale_id,
		s.default_region_id,
		s.default_stock_location_id,
		s.default_sales_channel_id,
		r.currency_code
		FROM store s
		LEFT JOIN region r ON r.id = s.default_region_id')!

	store_rows := store_data.rows()

	if store_rows.len == 0 {
		return error(format_error_message('No entries in table store'))
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
	default_currency_code, _ := v[8].get_string()!

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
		default_currency_code:         default_currency_code
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

fn model_store_currencies_retrieve(mut tx firebird.Transaction) ![]Currency {
	data := tx.execute('SELECT code, decimal_digits from currency c WHERE EXISTS (
	SELECT 1 from store_currencies sc WHERE sc.currency_code = c.code)')!

	rows := data.rows()

	mut currencies := []Currency{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()

		code, _ := v[0].get_string()!
		decimal_digits := v[1].get_null_i32()!

		currencies[i] = Currency{
			code:           code
			decimal_digits: decimal_digits
		}
	}

	return currencies
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

fn model_store_currencies_update(mut tx firebird.Transaction, id_bin []u8, currency_codes []string) ! {
	s := 'SELECT
		CAST(? AS BINARY(16)) AS store_id,
		CAST(? AS CHAR(3)) AS currency_code
		FROM RDB\$DATABASE'
	mut src := ''
	mut params := []firebird.Value{len: currency_codes.len * 2 + 2, init: firebird.Null{}}
	for i := 0; i < currency_codes.len; i++ {
		src = appendln(src, s)
		params[i * 2] = id_bin
		params[i * 2 + 1] = currency_codes[i]
		if i != currency_codes.len - 1 {
			src = appendln(src, 'UNION ALL')
		}
	}

	query := 'MERGE INTO store_currencies t
		USING (${src}) s (store_id, currency_code)
		ON (t.store_id = s.store_id AND t.currency_code = s.currency_code)
		WHEN NOT MATCHED THEN
			INSERT (store_id, currency_code)
			VALUES (s.store_id, s.currency_code)
		WHEN NOT MATCHED BY SOURCE
			AND t.store_id = ?
			AND t.currency_code <> (
				SELECT default_currency_code
				FROM store
				WHERE id = ?)
			THEN DELETE'
	params[params.len - 2] = id_bin
	params[params.len - 1] = id_bin
	tx.execute(query, ...params)!
}

fn model_store_update(mut tx firebird.Transaction, id_bin []u8, ph StoreRequestHygienised) ! {
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
	tx.execute('UPDATE store ${get_set_columns(columns)} WHERE id = ?', ...params)!
}
