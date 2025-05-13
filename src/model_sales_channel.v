module main

import einar_hjortdal.firebird

struct SalesChannel {
	id          string
	created_at  firebird.DateTime
	updated_at  firebird.DateTime
	deleted_at  firebird.DateTime
	name        string
	description string
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
		id,
		created_at,
		updated_at,
		deleted_at,
		name,
		description,
		is_disabled
		FROM sales_channel
		WHERE id = ?',
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

fn build_list_sales_channels_query(p ListSalesChannelsParams) string {
	base_query := 'SELECT 
		id,
		created_at,
		updated_at,
		deleted_at,
		is_disabled,
		name,
		description
		FROM sales_channel'
	mut conditions := ''
	return ''
}

fn (mut app App) list_sales_channels(p ListSalesChannelsParams) ![]SalesChannel {
	return []SalesChannel{}
}

struct NewSalesChannelData {
	name        string
	description string
	is_disabled bool
}

fn (mut app App) create_sales_channel(p NewSalesChannelData) !string {
	return ''
}

fn (mut app App) update_sales_channel(id string, p NewSalesChannelData) ! {
	return
}

fn (mut app App) delete_sales_channel(id string) ! {
	return
}
