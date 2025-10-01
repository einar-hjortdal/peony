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
	// mut:
	// stock_locations []StockLocation
}

fn model_sales_channel_retrieve_conditions(ph ListSalesChannelsParamsHygienised) (string, []firebird.Value) {
	mut params := []firebird.Value{}
	mut conditions := []string{}
	if ph.ids.is_set {
		conditions = arrays.concat(conditions, 'id IN (${get_placeholders(ph.ids_bin)})')
		params = arrays.concat(params, ...workaround_24757(ph.ids_bin))
	}

	if ph.name.is_set {
		conditions = arrays.concat(conditions, "name LIKE '%' || ? '%'")
		params = arrays.concat(params, ph.name.v)
	}

	if ph.description.is_set {
		conditions = arrays.concat(conditions, "description LIKE '%' || ? '%'")
		params = arrays.concat(params, ph.description.v)
	}

	if ph.product_ids.is_set {
		conditions = arrays.concat(conditions, 'EXISTS (
			SELECT 1 FROM product_sales_channel psc
			WHERE psc.sales_channel_id = sales_channel.id
				AND product_id IN (${get_placeholders(ph.product_ids_bin)})
			)')
		params = arrays.concat(params, ...workaround_24757(ph.product_ids_bin))
	}

	return get_where_conditions(conditions), params
}

fn model_sales_channel_retrieve_count(mut tx firebird.Transaction, ph ListSalesChannelsParamsHygienised) !i64 {
	conditions, params := model_sales_channel_retrieve_conditions(ph)
	data := tx.execute('SELECT COUNT(*) from sales_channel ${conditions}', ...params)!
	rows := data.rows()
	values := rows[0].values() // should always return one row
	count, _ := values[0].get_i64()! // should always return one column
	return count
}

fn model_sales_channel_retrieve(mut tx firebird.Transaction, ph ListSalesChannelsParamsHygienised) ![]SalesChannel {
	conditions, mut params := model_sales_channel_retrieve_conditions(ph)
	mut sorting := 'ORDER BY name ${get_sorting_order(ph.order)}'

	if ph.offset.is_set {
		sorting = appendln(sorting, 'OFFSET ? ROWS')
		params = arrays.concat(params, ph.offset.v)
	}

	if ph.fetch.is_set {
		sorting = appendln(sorting, 'FETCH NEXT ? ROWS ONLY')
		params = arrays.concat(params, ph.fetch.v)
	}

	data := tx.execute('SELECT
		id,
		created_at,
		updated_at,
		deleted_at,
		name,
		description,
		is_disabled
		FROM sales_channel
		${conditions}
		${sorting}',
		...params)!

	rows := data.rows()

	if rows.len == 0 {
		return []SalesChannel{}
	}

	mut sales_channels := []SalesChannel{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()

		id_bin, _ := v[0].get_array_u8()!
		created_at, _ := v[1].get_date_time()!
		updated_at, _ := v[2].get_date_time()!
		deleted_at, _ := v[3].get_date_time()!
		name, _ := v[4].get_string()!
		description, _ := v[5].get_string()!
		is_disabled, _ := v[6].get_bool()!

		id := id_bin_to_string(id_bin)!

		sales_channels[i] = SalesChannel{
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

	return sales_channels
}

fn model_sales_channel_create(mut tx firebird.Transaction, sales_channel_id_bin []u8, p SalesChannelRequest) ! {
	mut columns := ['id', 'name']
	mut params := [firebird.Value(sales_channel_id_bin), p.name]

	if description := p.description {
		columns = arrays.concat(columns, 'description')
		params = arrays.concat(params, description)
	}

	if is_disabled := p.is_disabled {
		columns = arrays.concat(columns, 'is_disabled')
		params = arrays.concat(params, is_disabled)
	}

	tx.execute('INSERT INTO sales_channel (${get_columns(columns)}) VALUES (${get_placeholders(columns)})',
		...params)!
}

fn model_sales_channel_update(mut tx firebird.Transaction, sales_channel_id_bin []u8, p SalesChannelUpdateRequest) ! {
	mut columns := []string{}
	mut params := []firebird.Value{}

	if name := p.name {
		columns = arrays.concat(columns, 'name')
		params = arrays.concat(params, name)
	}

	if description := p.description {
		columns = arrays.concat(columns, 'description')
		params = arrays.concat(params, description)
	}

	if is_disabled := p.is_disabled {
		columns = arrays.concat(columns, 'is_disabled')
		params = arrays.concat(params, is_disabled)
	}

	params = arrays.concat(params, sales_channel_id_bin)

	tx.execute('UPDATE sales_channel ${get_set_columns_with_updated_at(columns)} WHERE id = ?',
		...params)!
}

fn (mut app App) delete_sales_channel(id string) ! {
	id_bin := id_string_to_bin(id)!
	mut tx := app.start_transaction()!
	tx.execute('UPDATE sales_channel SET deleted_at = CURRENT_TIMESTAMP WHERE id = ?',
		id_bin)!
	tx.commit()!
}

struct ProductSalesChannel {
	product_id           string
	product_id_bin       []u8
	sales_channel_id     string
	sales_channel_id_bin []u8
}

fn model_product_sales_channel_retrieve(mut tx firebird.Transaction, product_ids_bin [][]u8) ![]ProductSalesChannel {
	data := tx.execute('SELECT product_id, sales_channel_id FROM product_sales_channel
		WHERE product_id IN (${get_placeholders(product_ids_bin)})',
		...workaround_24757(product_ids_bin))!

	rows := data.rows()

	mut product_sales_channels := []ProductSalesChannel{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()

		product_id_bin, _ := v[0].get_array_u8()!
		sales_channel_id_bin, _ := v[1].get_array_u8()!

		product_id := id_bin_to_string(product_id_bin)!
		sales_channel_id := id_bin_to_string(sales_channel_id_bin)!

		product_sales_channels[i] = ProductSalesChannel{
			product_id:           product_id
			product_id_bin:       product_id_bin
			sales_channel_id:     sales_channel_id
			sales_channel_id_bin: sales_channel_id_bin
		}
	}

	return product_sales_channels
}

fn model_product_sales_channel_update(mut tx firebird.Transaction, product_id_bin []u8, sales_channel_ids_bin [][]u8) ! {
	mut d := ''
	mut pa := []firebird.Value{}
	for i := 0; i < sales_channel_ids_bin.len; i++ {
		d = appendln(d, 'SELECT 
			CAST(? AS BINARY(16)) AS product_id,
			CAST(? AS BINARY(16)) AS sales_channel_id
			FROM RDB\$DATABASE')
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

struct SalesChannelStockLocation {
	sales_channel_id      string
	sales_channel_id_bin  []u8
	stock_location_id     string
	stock_location_id_bin []u8
}

struct ModelSalesChannelStockLocationRetrieveParams {
	stock_location_ids_bin [][]u8
	sales_channel_ids_bin  [][]u8
}

fn model_sales_channel_stock_location_retrieve(mut tx firebird.Transaction, p ModelSalesChannelStockLocationRetrieveParams) ![]SalesChannelStockLocation {
	if p.stock_location_ids_bin.len == 0 && p.sales_channel_ids_bin.len == 0 {
		return []SalesChannelStockLocation{}
	}

	if p.stock_location_ids_bin.len > 0 && p.sales_channel_ids_bin.len > 0 {
		return new_internal_error('received both stock_location_ids abd sales_channel_ids',
			'model_sales_channel_stock_location_retrieve')
	}

	mut condition := ''
	mut params := [][]u8{}
	if p.sales_channel_ids_bin.len > 0 {
		condition = 'sales_channel_id'
		params = p.sales_channel_ids_bin.clone()
	}

	if p.stock_location_ids_bin.len > 0 {
		condition = 'stock_location_id'
		params = p.stock_location_ids_bin.clone()
	}

	data := tx.execute('SELECT sales_channel_id, stock_location_id 
		FROM sales_channel_stock_location WHERE ${condition} IN (${get_placeholders(params)})',
		...workaround_24757(params))!

	rows := data.rows()

	mut sales_channel_stock_locations := []SalesChannelStockLocation{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()

		sales_channel_id_bin, _ := v[0].get_array_u8()!
		stock_location_id_bin, _ := v[1].get_array_u8()!

		sales_channel_id := id_bin_to_string(sales_channel_id_bin)!
		stock_location_id := id_bin_to_string(stock_location_id_bin)!

		sales_channel_stock_locations[i] = SalesChannelStockLocation{
			sales_channel_id:      sales_channel_id
			sales_channel_id_bin:  sales_channel_id_bin
			stock_location_id:     stock_location_id
			stock_location_id_bin: stock_location_id_bin
		}
	}
	return sales_channel_stock_locations
}

fn model_sales_channel_stock_location_add(mut tx firebird.Transaction, sales_channel_id_bin []u8, stock_location_id_bin []u8) ! {
	tx.execute('INSERT INTO sales_channel_stock_location (sales_channel_id, stock_location_id) 
		VALUES (?, ?)',
		sales_channel_id_bin, stock_location_id_bin)!
}

fn model_sales_channel_stock_location_delete(mut tx firebird.Transaction, sales_channel_id_bin []u8, stock_location_id_bin []u8) ! {
	tx.execute('DELETE FROM sales_channel_stock_location WHERE sales_channel_id = ? AND stock_location_id = ?)',
		sales_channel_id_bin, stock_location_id_bin)!
}
