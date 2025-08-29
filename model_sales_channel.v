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
	conditions, mut params := model_sales_channel_retrieve_conditions(ph)
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
