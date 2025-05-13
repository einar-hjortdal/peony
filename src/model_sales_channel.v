module main

import arrays
import einar_hjortdal.firebird

struct SalesChannel {
	id          string
	created_at  firebird.DateTime
	updated_at  firebird.DateTime
	deleted_at  firebird.DateTime @[omitempty]
	name        string
	description string @[omitempty]
	is_disabled bool
}

fn parse_sales_channel(v []firebird.Value) !SalesChannel {
	id, _ := v[0].get_string()!
	created_at, _ := v[1].get_date_time()!
	updated_at, _ := v[2].get_date_time()!
	deleted_at, _ := v[3].get_date_time()!
	name, _ := v[4].get_string()!
	description, _ := v[5].get_string()!
	is_disabled, _ := v[6].get_bool()!

	return SalesChannel{
		id:          id
		created_at:  created_at
		updated_at:  updated_at
		deleted_at:  deleted_at
		name:        name
		description: description
		is_disabled: is_disabled
	}
}

fn (mut app App) retrieve_sales_channel_by_id(id string) !SalesChannel {
	mut tx := app.fb.start_transaction(firebird.isolation_level_read_commited)!
	data := tx.execute('SELECT 
		UUID_TO_CHAR(id),
		created_at,
		updated_at,
		deleted_at,
		name,
		description,
		is_disabled
		FROM sales_channel
		WHERE id = CHAR_TO_UUID(?)',
		id)!
	tx.rollback()!

	if data.rows.len == 0 {
		return error(format_error_message('No sales channel found'))
	}
	return parse_sales_channel(data.rows[0].values)!
}

struct ListSalesChannelsParams {
	id          []string
	name        string
	description string
	offset      i32
	fetch       i32
	order       string
}

fn build_list_sales_channels_query(p ListSalesChannelsParams) (string, []firebird.Value) {
	base_query := 'SELECT 
		UUID_TO_CHAR(id),
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
	if p.id.len > 0 {
		c = arrays.concat(c, 'UUID_TO_CHAR(id) IN (${get_placeholders(p.id)})')
		params = arrays.concat(params, ...p.id)
	}

	// Add condition for name using LIKE with wildcards.
	if p.name != '' {
		c = arrays.concat(c, "name LIKE '%' || ? '%'")
		params = arrays.concat(params, p.name)
	}

	// Add condition for description if provided.
	if p.description != '' {
		c = arrays.concat(c, "description LIKE '%' || ? '%'")
		params = arrays.concat(params, p.description)
	}

	mut sorting := ''
	if p.offset != 0 {
		sorting = appendln(sorting, 'OFFSET ? ROWS')
		params = arrays.concat(params, p.offset)
	}
	if p.fetch != 0 {
		sorting = appendln(sorting, 'FETCH NEXT ? ROWS ONLY')
		params = arrays.concat(params, p.fetch)
	}
	sorting = appendln(sorting, 'ORDER BY name ${parse_order(p.order)}')
	return '${base_query}${get_where_conditions(c)}${sorting}', params
}

fn (mut app App) list_sales_channels(p ListSalesChannelsParams) ![]SalesChannel {
	mut tx := app.fb.start_transaction(firebird.isolation_level_read_commited)!
	query, params := build_list_sales_channels_query(p)
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

fn build_create_sales_channel_query(id string, p NewSalesChannelData) (string, []firebird.Value) {
	mut col := ['name']
	mut params := [firebird.Value(id), p.name]
	if p.description != '' {
		col = arrays.concat(col, 'description')
		params = arrays.concat(params, p.description)
	}
	if p.is_disabled {
		col = arrays.concat(col, 'is_disabled')
		params = arrays.concat(params, p.is_disabled)
	}

	query := 'INSERT INTO sales_channel (
		id, ${get_columns(col)}) 
		VALUES (CHAR_TO_UUID(?), ${get_placeholders(col)})'

	return query, params
}

fn (mut app App) create_sales_channel(p NewSalesChannelData) !string {
	id := app.luuid_generator.v1()
	query, params := build_create_sales_channel_query(id, p)
	mut tx := app.fb.start_transaction(firebird.isolation_level_read_commited)!
	tx.execute(query, ...params)!
	tx.commit()!
	return id
}

fn (mut app App) update_sales_channel(id string, p NewSalesChannelData) ! {
	mut tx := app.fb.start_transaction(firebird.isolation_level_read_commited)!
	tx.execute('UPDATE sales_channel SET 
		name = ?
		description = ?
		is_disabled = ?
		WHERE id = CHAR_TO_UUID(?)',
		p.name, p.is_disabled, p.description, id)!
	tx.commit()!
	return
}

fn (mut app App) delete_sales_channel(id string) ! {
	mut tx := app.fb.start_transaction(firebird.isolation_level_read_commited)!
	tx.execute('UPDATE sales_channel SET deleted_at = CURRENT_TIMESTAMP WHERE id = CHAR_TO_UUID(?)',
		id)!
	tx.commit()!
}
