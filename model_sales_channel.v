module peony

import arrays
import einar_hjortdal.firebird

struct SalesChannel {
	id          ID
	created_at  firebird.DateTime
	updated_at  firebird.DateTime
	deleted_at  firebird.DateTime
	name        string
	description string
	is_disabled bool
	// mut:
	// stock_locations []StockLocation
}

fn (sc SalesChannel) id() ID {
	return sc.id
}

struct SalesChannelRetrieveParams {
	ids    ?[]ID
	offset i32
	fetch  i32
	order  string
}

fn model_sales_channel_retrieve_conditions(p SalesChannelRetrieveParams) (string, []firebird.Value) {
	mut conditions := []string{}
	mut params := []firebird.Value{}

	if ids := p.ids {
		conditions = arrays.concat(conditions, 'id IN (${get_placeholders(ids)})')
		params = arrays.concat(params, ...ids_bytes(ids))
	}

	return get_where_conditions(conditions), params
}

fn model_sales_channel_retrieve_count(mut tx firebird.Transaction, p SalesChannelRetrieveParams) !i64 {
	conditions, params := model_sales_channel_retrieve_conditions(p)
	query := 'SELECT COUNT(*) FROM sales_channel ${conditions}'
	data := tx.execute(query, ...params)!
	rows := data.rows()
	values := rows[0].values() // should always return one row
	count, _ := values[0].get_i64()! // should always return one column
	return count
}

fn model_sales_channel_retrieve(mut tx firebird.Transaction, p SalesChannelRetrieveParams) ![]SalesChannel {
	conditions, mut params := model_sales_channel_retrieve_conditions(p)
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
		description,
		is_disabled
		FROM sales_channel
		${conditions}
		${sorting}'
	data := tx.execute(query, ...params)!

	rows := data.rows()

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

		id := id_from_bytes(id_bin)!

		sales_channels[i] = SalesChannel{
			id:          id
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

fn model_sales_channel_create(mut tx firebird.Transaction, sales_channel_id ID, p SalesChannelRequest) ! {
	mut columns := ['id', 'name']
	mut params := [firebird.Value(sales_channel_id.bytes()), p.name]

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

fn model_sales_channel_update(mut tx firebird.Transaction, sales_channel_id ID, p SalesChannelUpdateRequest) ! {
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

	params = arrays.concat(params, sales_channel_id.bytes())

	tx.execute('UPDATE sales_channel ${get_set_columns_with_updated_at(columns)} WHERE id = ?',
		...params)!
}

fn model_sales_channel_delete(mut tx firebird.Transaction, sales_channel_id ID) ! {
	tx.execute('UPDATE sales_channel SET deleted_at = CURRENT_TIMESTAMP WHERE id = ?',
		sales_channel_id.bytes())!
}

struct ProductSalesChannel {
	product_id       ID
	sales_channel_id ID
}

fn model_product_sales_channel_retrieve(mut tx firebird.Transaction, product_ids_bin [][]u8) ![]ProductSalesChannel {
	data := tx.execute('SELECT product_id, sales_channel_id FROM product_sales_channel
		WHERE product_id IN (${get_placeholders(product_ids_bin)})',
		...product_ids_bin)!

	rows := data.rows()

	mut product_sales_channels := []ProductSalesChannel{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()

		product_id_bin, _ := v[0].get_array_u8()!
		sales_channel_id_bin, _ := v[1].get_array_u8()!

		product_id := id_from_bytes(product_id_bin)!
		sales_channel_id := id_from_bytes(sales_channel_id_bin)!

		product_sales_channels[i] = ProductSalesChannel{
			product_id:       product_id
			sales_channel_id: sales_channel_id
		}
	}

	return product_sales_channels
}

fn model_product_sales_channel_update(mut tx firebird.Transaction, product_id ID, sales_channel_ids []ID) ! {
	mut d := ''
	mut pa := []firebird.Value{}
	for i := 0; i < sales_channel_ids.len; i++ {
		d = appendln(d, 'SELECT 
			CAST(? AS BINARY(16)) AS product_id,
			CAST(? AS BINARY(16)) AS sales_channel_id
			FROM RDB\$DATABASE')
		pa = arrays.concat(pa, product_id.bytes(), sales_channel_ids[i].bytes())
		if i != sales_channel_ids.len - 1 {
			d = appendln(d, 'UNION ALL')
		}
	}

	query := 'MERGE INTO product_sales_channel t
			USING (${d}) s (product_id, sales_channel_id)
			ON t.product_id = s.product_id AND t.sales_channel_id = s.sales_channel_id
			WHEN NOT MATCHED THEN 
				INSERT (product_id, sales_channel_id) 
				VALUES (s.product_id, s.sales_channel_id)
				WHEN NOT MATCHED BY SOURCE AND t.product_id = ? THEN DELETE'
	pa = arrays.concat(pa, product_id.bytes())
	tx.execute(query, ...pa)!
}

struct SalesChannelStockLocation {
	sales_channel_id  ID
	stock_location_id ID
}

struct ModelSalesChannelStockLocationRetrieveParams {
	stock_location_ids ?[]ID
	sales_channel_ids  ?[]ID
}

fn model_sales_channel_stock_location_retrieve(mut tx firebird.Transaction, p ModelSalesChannelStockLocationRetrieveParams) ![]SalesChannelStockLocation {
	if p.stock_location_ids == none && p.sales_channel_ids == none {
		return []SalesChannelStockLocation{}
	}

	if p.stock_location_ids != none && p.sales_channel_ids != none {
		return new_error_internal('received both stock_location_ids abd sales_channel_ids',
			'model_sales_channel_stock_location_retrieve')
	}

	mut condition := ''
	mut params := []firebird.Value{}
	if sales_channel_ids := p.sales_channel_ids {
		condition = 'sales_channel_id'
		params = slices_to_values(ids_bytes(sales_channel_ids))
	}

	if stock_location_ids := p.stock_location_ids {
		condition = 'stock_location_id'
		params = slices_to_values(ids_bytes(stock_location_ids))
	}

	data := tx.execute('SELECT sales_channel_id, stock_location_id 
		FROM sales_channel_stock_location WHERE ${condition} IN (${get_placeholders(params)})',
		...params)!

	rows := data.rows()

	mut sales_channel_stock_locations := []SalesChannelStockLocation{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()

		sales_channel_id_bin, _ := v[0].get_array_u8()!
		stock_location_id_bin, _ := v[1].get_array_u8()!

		sales_channel_id := id_from_bytes(sales_channel_id_bin)!
		stock_location_id := id_from_bytes(stock_location_id_bin)!

		sales_channel_stock_locations[i] = SalesChannelStockLocation{
			sales_channel_id:  sales_channel_id
			stock_location_id: stock_location_id
		}
	}
	return sales_channel_stock_locations
}

fn model_sales_channel_stock_location_add(mut tx firebird.Transaction, sales_channel_id ID, stock_location_id ID) ! {
	tx.execute('INSERT INTO sales_channel_stock_location (sales_channel_id, stock_location_id) 
		VALUES (?, ?)',
		sales_channel_id.bytes(), stock_location_id.bytes())!
}

fn model_sales_channel_stock_location_delete(mut tx firebird.Transaction, sales_channel_id ID, stock_location_id ID) ! {
	tx.execute('DELETE FROM sales_channel_stock_location WHERE sales_channel_id = ? AND stock_location_id = ?)',
		sales_channel_id.bytes(), stock_location_id.bytes())!
}

