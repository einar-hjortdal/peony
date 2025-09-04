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
	default_currency_code         string
	default_stock_location_id     string
	default_stock_location_id_bin []u8
	default_sales_channel_id      string
	default_sales_channel_id_bin  []u8
mut:
	locales    []Locale
	currencies []Currency
	// stock locations
	// sales_channels
}

fn parse_store(v []firebird.Value) !Store {
	id_bin, _ := v[0].get_array_u8()!
	created_at, _ := v[1].get_date_time()!
	updated_at, _ := v[2].get_date_time()!
	name, _ := v[3].get_string()!
	default_locale_id_bin, _ := v[4].get_array_u8()!
	default_currency_code, _ := v[5].get_string()!
	default_stock_location_id_bin, default_stock_location_id_bin_is_null := v[6].get_array_u8()!
	default_sales_channel_id_bin, default_sales_channel_id_bin_is_null := v[7].get_array_u8()!

	id := id_bin_to_string(id_bin)!
	default_locale_id := id_bin_to_string(default_locale_id_bin)!

	mut default_stock_location_id := ''
	mut default_sales_channel_id := ''

	if !default_stock_location_id_bin_is_null {
		default_stock_location_id = id_bin_to_string(default_stock_location_id_bin)!
	}

	if !default_sales_channel_id_bin_is_null {
		default_sales_channel_id = id_bin_to_string(default_sales_channel_id_bin)!
	}

	return Store{
		id:                            id
		id_bin:                        id_bin
		created_at:                    created_at
		updated_at:                    updated_at
		name:                          name
		default_locale_id:             default_locale_id
		default_locale_id_bin:         default_locale_id_bin
		default_currency_code:         default_currency_code
		default_stock_location_id:     default_stock_location_id
		default_stock_location_id_bin: default_stock_location_id_bin
		default_sales_channel_id:      default_sales_channel_id
		default_sales_channel_id_bin:  default_sales_channel_id_bin
	}
}

// TODO separate queries (create suite)
fn model_store_retrieve(mut tx firebird.Transaction) !Store {
	store_data := tx.execute('SELECT
		id,
		created_at,
		updated_at,
		name,
		default_locale_id,
		default_currency_code,
		default_stock_location_id,
		default_sales_channel_id
		FROM store')!

	store_rows := store_data.rows()

	if store_rows.len == 0 {
		return error(format_error_message('No entries in table store'))
	}

	mut store := parse_store(store_rows[0].values())!

	locale_data := tx.execute('SELECT locale_id, l.code
		FROM store_locales
		LEFT JOIN locale l ON locale_id = l.id
		WHERE store_id = ?
		ORDER BY l.code',
		store.id_bin)!

	locale_rows := locale_data.rows()

	mut locales := []Locale{len: locale_rows.len}
	for i := 0; i < locale_rows.len; i++ {
		v := locale_rows[i].values()

		id_bin, _ := v[0].get_array_u8()!
		code, _ := v[1].get_string()!

		id := id_bin_to_string(id_bin)!

		locales[i] = Locale{
			id:     id
			id_bin: id_bin
			code:   code
		}
	}

	store.locales = locales

	currency_data := tx.execute('SELECT currency_code, c.decimal_digits, c.includes_tax 
		FROM store_currencies
		LEFT JOIN currency c ON currency_code = c.code
		WHERE store_id = ?
		ORDER BY c.code',
		store.id_bin)!

	currency_rows := currency_data.rows()

	mut currencies := []Currency{len: currency_rows.len}
	for i := 0; i < currency_rows.len; i++ {
		currencies[i] = parse_currency(currency_rows[i].values())!
	}

	store.currencies = currencies

	return store
}

fn (mut app App) do_update_store_locales(mut tx firebird.Transaction, id_bin []u8, locale_ids_bin [][]u8) ! {
	s := 'SELECT
		CAST(? AS BINARY(16)) AS store_id,
		CAST(? AS BINARY(16)) AS locale_id
		FROM RDB\$DATABASE'
	mut src := ''
	mut params := []firebird.Value{len: locale_ids_bin.len * 2 + 2, init: firebird.Value(firebird.Null{})}
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

fn (mut app App) do_update_store_currencies(mut tx firebird.Transaction, id_bin []u8, currency_codes []string) ! {
	s := 'SELECT
		CAST(? AS BINARY(16)) AS store_id,
		CAST(? AS CHAR(3)) AS currency_code
		FROM RDB\$DATABASE'
	mut src := ''
	mut params := []firebird.Value{len: currency_codes.len * 2 + 2, init: firebird.Value(firebird.Null{})}
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

fn (mut app App) do_store_update(mut tx firebird.Transaction, id_bin []u8, ph StoreRequestHygienised) ! {
	mut query := 'UPDATE store SET'
	mut params := []firebird.Value{}

	if name := ph.name {
		query = appendln(query, 'name = ?')
		params = arrays.concat(params, name)
	}

	if ph.default_locale_id != none {
		query = appendln(query, 'default_locale_id = ?')
		params = arrays.concat(params, ph.default_locale_id_bin)
	}

	if default_currency_code := ph.default_currency_code {
		query = appendln(query, 'default_currency_code = ?')
		params = arrays.concat(params, default_currency_code)
	}

	if ph.default_stock_location_id != none {
		query = appendln(query, 'default_stock_location_id = ?')
		params = arrays.concat(params, ph.default_stock_location_id_bin)
	}

	if ph.default_sales_channel_id != none {
		query = appendln(query, 'default_sales_channel_id = ?')
		params = arrays.concat(params, ph.default_sales_channel_id_bin)
	}

	conditions := 'WHERE id = ?'
	query = appendln(query, conditions)
	params = arrays.concat(params, id_bin)
	tx.execute(query, ...params)!
}
