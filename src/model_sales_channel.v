module main

import arrays
import einar_hjortdal.firebird

struct SalesChannel {
	id          string
	id_bin      []u8 @[json: '-']
	created_at  firebird.DateTime
	updated_at  firebird.DateTime
	deleted_at  firebird.DateTime @[omitempty]
	name        string
	description string @[omitempty]
	is_disabled bool
}

fn parse_sales_channel(v []firebird.Value) !SalesChannel {
	id_bin, _ := v[0].get_array_u8()!
	created_at, _ := v[1].get_date_time()!
	updated_at, _ := v[2].get_date_time()!
	deleted_at, _ := v[3].get_date_time()!
	name, _ := v[4].get_string()!
	description, _ := v[5].get_string()!
	is_disabled, _ := v[6].get_bool()!

	id := id_bin_to_string(id_bin)!

	return SalesChannel{
		id:          id
		id_bin:      id_bin
		created_at:  created_at
		updated_at:  updated_at
		deleted_at:  deleted_at
		name:        name
		description: description
		is_disabled: is_disabled
	}
}

fn (mut app App) retrieve_sales_channel_by_id(id string) !SalesChannel {
	id_bin := id_string_to_bin(id)!
	mut tx := app.fb.start_transaction(firebird.isolation_level_read_commited)!
	data := tx.execute('SELECT 
		id,
		created_at,
		updated_at,
		deleted_at,
		name,
		description,
		is_disabled
		FROM sales_channel
		WHERE id = ?',
		id_bin)!
	tx.rollback()!

	if data.rows.len == 0 {
		return error(format_error_message('No sales channel found'))
	}
	return parse_sales_channel(data.rows[0].values)!
}

struct ListSalesChannelsParams {
	ids         ZeroArrayString
	name        ZeroString
	description ZeroString
	offset      ZeroI32
	fetch       ZeroI32
	order       ZeroString
}

fn extract_retrieve_sales_channels_params(p map[string]string) ListSalesChannelsParams {
	return ListSalesChannelsParams{
		ids:         zero_array_string(p, 'ids')
		name:        zero_string(p, 'name')
		description: zero_string(p, 'description')
		offset:      zero_i32(p, 'offset')
		fetch:       zero_i32(p, 'fetch')
		order:       zero_string(p, 'order')
	}
}

fn build_list_sales_channels_query(p ListSalesChannelsParams) !(string, []firebird.Value) {
	base_query := 'SELECT
		id,
		created_at,
		updated_at,
		deleted_at,
		is_disabled,
		name,
		description
		FROM sales_channel'
	mut params := []firebird.Value{}
	mut c := []string{}
	// Check if id array is not empty (we'll form a SQL IN clause).
	if p.ids.is_set {
		mut ids_bin := [][]u8{}
		for i := 0; i < p.ids.v.len; i++ {
			id_bin := id_string_to_bin(p.ids.v[i])!
			ids_bin = arrays.concat(ids_bin, id_bin)
		}
		c = arrays.concat(c, 'id IN (${get_placeholders(p.ids.v)})')
		params = arrays.concat(params, ...ids_bin)
	}

	// Add condition for name using LIKE with wildcards.
	if p.name.is_set {
		c = arrays.concat(c, "name LIKE '%' || ? '%'")
		params = arrays.concat(params, p.name.v)
	}

	// Add condition for description if provided.
	if p.description.is_set {
		c = arrays.concat(c, "description LIKE '%' || ? '%'")
		params = arrays.concat(params, p.description.v)
	}

	mut sorting := ''
	if p.offset.is_set {
		sorting = appendln(sorting, 'OFFSET ? ROWS')
		params = arrays.concat(params, p.offset.v)
	}

	if p.fetch.is_set {
		sorting = appendln(sorting, 'FETCH NEXT ? ROWS ONLY')
		params = arrays.concat(params, get_fetch_amount(p.fetch))
	}

	sorting = appendln(sorting, 'ORDER BY name ${get_sorting_order(p.order)}')
	return '${base_query}${get_where_conditions(c)}${sorting}', params
}

fn (mut app App) list_sales_channels(p ListSalesChannelsParams) ![]SalesChannel {
	mut tx := app.fb.start_transaction(firebird.isolation_level_read_commited)!
	query, params := build_list_sales_channels_query(p)!
	data := tx.execute(query, ...params)!
	tx.rollback()!

	mut sales_channels := []SalesChannel{}
	for i := 0; i < data.rows.len; i++ {
		sales_channel := parse_sales_channel(data.rows[i].values)!
		sales_channels = arrays.concat(sales_channels, sales_channel)
	}
	return sales_channels
}

struct NewSalesChannelData {
	name        string
	description string @[omitempty]
	is_disabled bool
}

fn build_create_sales_channel_query(id_bin []u8, p NewSalesChannelData) !(string, []firebird.Value) {
	mut col := ['id', 'name']
	mut params := [firebird.Value(id_bin), p.name]
	if p.description != '' {
		col = arrays.concat(col, 'description')
		params = arrays.concat(params, p.description)
	}
	if p.is_disabled {
		col = arrays.concat(col, 'is_disabled')
		params = arrays.concat(params, p.is_disabled)
	}

	query := 'INSERT INTO sales_channel (${get_columns(col)}) VALUES (${get_placeholders(col)})'

	return query, params
}

fn (mut app App) create_sales_channel(p NewSalesChannelData) !(string, []u8) {
	id, id_bin := app.new_id()!
	query, params := build_create_sales_channel_query(id_bin, p)!
	mut tx := app.fb.start_transaction(firebird.isolation_level_read_commited)!
	tx.execute(query, ...params)!
	tx.commit()!
	return id, id_bin
}

fn (mut app App) update_sales_channel(id string, p NewSalesChannelData) ! {
	id_bin := id_string_to_bin(id)!
	mut tx := app.fb.start_transaction(firebird.isolation_level_read_commited)!
	tx.execute('UPDATE sales_channel SET 
		name = ?
		description = ?
		is_disabled = ?
		WHERE id = ?',
		p.name, p.is_disabled, p.description, id_bin)!
	tx.commit()!
	return
}

fn (mut app App) delete_sales_channel(id string) ! {
	id_bin := id_string_to_bin(id)!
	mut tx := app.fb.start_transaction(firebird.isolation_level_read_commited)!
	tx.execute('UPDATE sales_channel SET deleted_at = CURRENT_TIMESTAMP WHERE id = ?',
		id_bin)!
	tx.commit()!
}

fn (mut app App) add_products_to_sales_channel(id string, products_ids []string) ! {
	id_bin := id_string_to_bin(id)!
	mut tx := app.fb.start_transaction(firebird.isolation_level_read_commited)!
	mut stmt := tx.prepare('INSERT INTO product_sales_channel (
		product_id, sales_channel_id) VALUES (?, ?)')!
	for i := 0; i < products_ids.len; i++ {
		pid_bin := id_string_to_bin(products_ids[i])!
		stmt.execute(pid_bin, id_bin)!
	}
	tx.commit()!
}

fn (mut app App) do_update_product_sales_channels(mut tx firebird.Transaction, product_id_bin []u8, sales_channel_ids_bin [][]u8) ! {
	mut d := ''
	mut pa := []firebird.Value{}
	for i := 0; i < sales_channel_ids_bin.len; i++ {
		d = appendln(d, 'SELECT ? AS product_id, ? AS sales_channel_id FROM RDB\$DATABASE')
		pa = arrays.concat(pa, product_id_bin, sales_channel_ids_bin[i])
		if i != sales_channel_ids_bin.len - 1 {
			d = appendln(d, 'UNION ALL')
		}
	}

	query := 'MERGE INTO product_sales_channel t
			USING (${d}) s (product_id, sales_channel_id)
			ON (t.product_id = s.product_id AND t.sales_channel_id = s.sales_channel_id)
			WHEN NOT MATCHED THEN 
				INSERT (product_id, sales_channel_id) 
				VALUES (s.product_id, s.sales_channel_id)
				WHEN NOT MATCHED BY SOURCE AND t.product_id = ? THEN DELETE'
	pa = arrays.concat(pa, product_id_bin)

	tx.execute(query, ...pa)!
}
