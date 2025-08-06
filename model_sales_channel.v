module peony

import arrays
import einar_hjortdal.firebird

struct SalesChannel {
	id          string
	id_bin      []u8
	created_at  firebird.DateTime
	updated_at  firebird.DateTime
	deleted_at  firebird.DateTime
	name        string
	description string
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

fn do_retrieve_sales_channels(mut tx firebird.Transaction) ![]SalesChannel {
	data := tx.execute('SELECT 
		id,
		created_at,
		updated_at,
		deleted_at,
		name,
		description,
		is_disabled
		FROM sales_channel')!

	mut sales_channels := []SalesChannel{len: data.rows.len}
	for i := 0; i < data.rows.len; i++ {
		sales_channels[i] = parse_sales_channel(data.rows[i].values)!
	}
	return sales_channels
}

fn do_retrieve_sales_channels_by_ids(mut tx firebird.Transaction, ids_bin [][]u8) ![]SalesChannel {
	data := tx.execute('SELECT 
		id,
		created_at,
		updated_at,
		deleted_at,
		name,
		description,
		is_disabled
		FROM sales_channel
		WHERE id IN (${get_n_placeholders(i32(ids_bin.len))})',
		...workaround_24757(ids_bin))!

	mut sales_channels := []SalesChannel{len: data.rows.len}
	for i := 0; i < data.rows.len; i++ {
		sales_channels[i] = parse_sales_channel(data.rows[i].values)!
	}
	return sales_channels
}

fn (mut app App) list_sales_channels(mut tx firebird.Transaction, ph ListSalesChannelsParamsHygienised) !([]SalesChannel, i64) {
	base_query := 'SELECT
		id,
		created_at,
		updated_at,
		deleted_at,
		name,
		description,
		is_disabled,
		COUNT(*) OVER()
		FROM sales_channel'
	mut params := []firebird.Value{}
	mut c := []string{}
	// Check if id array is not empty (we'll form a SQL IN clause).
	if ph.ids.is_set {
		c = arrays.concat(c, 'id IN (${get_n_placeholders(i32(ph.ids_bin.len))})')
		params = arrays.concat(params, ...ph.ids_bin)
	}

	// Add condition for name using LIKE with wildcards.
	if ph.name.is_set {
		c = arrays.concat(c, "name LIKE '%' || ? '%'")
		params = arrays.concat(params, ph.name.v)
	}

	// Add condition for description if provided.
	if ph.description.is_set {
		c = arrays.concat(c, "description LIKE '%' || ? '%'")
		params = arrays.concat(params, ph.description.v)
	}

	mut sorting := ''
	sorting = appendln(sorting, 'ORDER BY name ${get_sorting_order(ph.order)}')

	if ph.offset.is_set {
		sorting = appendln(sorting, 'OFFSET ? ROWS')
		params = arrays.concat(params, ph.offset.v)
	}

	if ph.fetch.is_set {
		sorting = appendln(sorting, 'FETCH NEXT ? ROWS ONLY')
		params = arrays.concat(params, get_fetch_amount(ph.fetch))
	}

	data := tx.execute('${base_query}${get_where_conditions(c)}${sorting}', ...params)!

	if data.rows.len == 0 {
		return []SalesChannel{}, 0
	}

	count, _ := data.rows[0].values[7].get_i64()!
	mut sales_channels := []SalesChannel{len: data.rows.len}
	for i := 0; i < data.rows.len; i++ {
		sales_channels[i] = parse_sales_channel(data.rows[i].values[..7])!
	}
	return sales_channels, count
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
	id, id_bin := app.new_id()
	query, params := build_create_sales_channel_query(id_bin, p)!
	mut tx := app.start_transaction()!
	tx.execute(query, ...params)!
	tx.commit()!
	return id, id_bin
}

fn (mut app App) update_sales_channel(id string, p NewSalesChannelData) ! {
	id_bin := id_string_to_bin(id)!
	mut tx := app.start_transaction()!
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
	mut tx := app.start_transaction()!
	tx.execute('UPDATE sales_channel SET deleted_at = CURRENT_TIMESTAMP WHERE id = ?',
		id_bin)!
	tx.commit()!
}

fn (mut app App) add_products_to_sales_channel(id string, products_ids []string) ! {
	id_bin := id_string_to_bin(id)!
	mut tx := app.start_transaction()!
	mut stmt := tx.prepare('INSERT INTO product_sales_channel (
		product_id, sales_channel_id) VALUES (?, ?)')!
	for i := 0; i < products_ids.len; i++ {
		pid_bin := id_string_to_bin(products_ids[i])!
		stmt.execute(pid_bin, id_bin)!
	}
	tx.commit()!
}

struct ProductSalesChannel {
	product_id           string
	product_id_bin       []u8
	sales_channel_id     string
	sales_channel_id_bin []u8
}

fn parse_product_sales_channel(v []firebird.Value) !ProductSalesChannel {
	product_id_bin, _ := v[0].get_array_u8()!
	sales_channel_id_bin, _ := v[1].get_array_u8()!

	product_id := id_bin_to_string(product_id_bin)!
	sales_channel_id := id_bin_to_string(sales_channel_id_bin)!

	return ProductSalesChannel{
		product_id:           product_id
		product_id_bin:       product_id_bin
		sales_channel_id:     sales_channel_id
		sales_channel_id_bin: sales_channel_id_bin
	}
}

fn do_retrieve_product_sales_channels(mut tx firebird.Transaction, product_ids_bin [][]u8) ![]ProductSalesChannel {
	data := tx.execute('SELECT
		product_id,
		sales_channel_id
		FROM product_sales_channel
		WHERE product_id IN (${get_n_placeholders(i32(product_ids_bin.len))})',
		...workaround_24757(product_ids_bin))!

	mut product_sales_channels := []ProductSalesChannel{len: data.rows.len}
	for i := 0; i < data.rows.len; i++ {
		product_sales_channels[i] = parse_product_sales_channel(data.rows[i].values)!
	}

	return product_sales_channels
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
