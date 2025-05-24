module main

import arrays
import einar_hjortdal.firebird

struct ProductVariant {
	id                 string
	created_at         firebird.DateTime
	updated_at         firebird.DateTime
	deleted_at         firebird.DateTime @[omitempty]
	product_id         string
	sku                string @[omitempty]
	barcode            string @[omitempty]
	ean                string @[omitempty]
	upc                string @[omitempty]
	variant_rank       i32
	inventory_quantity i32
	allow_backorder    bool
	manage_inventory   bool
	hs_code            string @[omitempty]
	origin_country     string @[omitempty]
	mid_code           string @[omitempty]
	weight             i32    @[omitempty]
	length             i32    @[omitempty]
	height             i32    @[omitempty]
	width              i32    @[omitempty]
	title              string
	money_amounts      []MoneyAmount @[omitempty]
	// options
}

struct ProductVariantRow {
	id                         string
	created_at                 firebird.DateTime
	updated_at                 firebird.DateTime
	deleted_at                 firebird.DateTime
	product_id                 string
	sku                        string
	barcode                    string
	ean                        string
	upc                        string
	variant_rank               i32
	inventory_quantity         i32
	allow_backorder            bool
	manage_inventory           bool
	hs_code                    string
	origin_country             string
	mid_code                   string
	weight                     i32
	length                     i32
	height                     i32
	width                      i32
	title                      string
	money_amount_id            string
	money_amount_created_at    firebird.DateTime
	money_amount_updated_at    firebird.DateTime
	money_amount_deleted_at    firebird.DateTime
	money_amount_currency_code string
	money_amount_amount        i32
	money_amount_min_quantity  i32
	money_amount_max_quantity  i32
	money_amount_price_list_id string
	money_amount_region_id     string
}

fn parse_product_variant_row(v []firebird.Value) !ProductVariantRow {
	id_bin, _ := v[0].get_array_u8()!
	created_at, _ := v[1].get_date_time()!
	updated_at, _ := v[2].get_date_time()!
	deleted_at, _ := v[3].get_date_time()!
	product_id_bin, _ := v[4].get_array_u8()!
	sku, _ := v[5].get_string()!
	barcode, _ := v[6].get_string()!
	ean, _ := v[7].get_string()!
	upc, _ := v[8].get_string()!
	variant_rank, _ := v[9].get_i32()!
	inventory_quantity, _ := v[10].get_i32()!
	allow_backorder, _ := v[11].get_bool()!
	manage_inventory, _ := v[12].get_bool()!
	hs_code, _ := v[13].get_string()!
	origin_country, _ := v[14].get_string()!
	mid_code, _ := v[15].get_string()!
	weight, _ := v[16].get_i32()!
	length, _ := v[17].get_i32()!
	height, _ := v[18].get_i32()!
	width, _ := v[19].get_i32()!
	title, _ := v[20].get_string()!

	id := id_from_bin(id_bin)!
	product_id := id_from_bin(product_id_bin)!

	money_amount_id_bin, money_amount_id_bin_is_null := v[21].get_array_u8()!
	money_amount_created_at, _ := v[22].get_date_time()!
	money_amount_updated_at, _ := v[23].get_date_time()!
	money_amount_deleted_at, _ := v[24].get_date_time()!
	money_amount_currency_code, _ := v[25].get_string()!
	money_amount_amount, _ := v[26].get_i32()!
	money_amount_min_quantity, _ := v[27].get_i32()!
	money_amount_max_quantity, _ := v[28].get_i32()!
	money_amount_price_list_id_bin, money_amount_price_list_id_is_null := v[29].get_array_u8()!
	money_amount_region_id_bin, money_amount_region_id_is_null := v[30].get_array_u8()!

	mut money_amount_id := ''
	mut money_amount_price_list_id := ''
	mut money_amount_region_id := ''

	if !money_amount_id_bin_is_null {
		money_amount_id = id_from_bin(money_amount_id_bin)!
	}

	if !money_amount_price_list_id_is_null {
		money_amount_price_list_id = id_from_bin(money_amount_price_list_id_bin)!
	}

	if !money_amount_region_id_is_null {
		money_amount_region_id = id_from_bin(money_amount_region_id_bin)!
	}

	return ProductVariantRow{
		id:                         id
		created_at:                 created_at
		updated_at:                 updated_at
		deleted_at:                 deleted_at
		product_id:                 product_id
		sku:                        sku
		barcode:                    barcode
		ean:                        ean
		upc:                        upc
		variant_rank:               variant_rank
		inventory_quantity:         inventory_quantity
		allow_backorder:            allow_backorder
		manage_inventory:           manage_inventory
		hs_code:                    hs_code
		origin_country:             origin_country
		mid_code:                   mid_code
		weight:                     weight
		length:                     length
		height:                     height
		width:                      width
		title:                      title
		money_amount_id:            money_amount_id
		money_amount_created_at:    money_amount_created_at
		money_amount_updated_at:    money_amount_updated_at
		money_amount_deleted_at:    money_amount_deleted_at
		money_amount_currency_code: money_amount_currency_code
		money_amount_amount:        money_amount_amount
		money_amount_min_quantity:  money_amount_min_quantity
		money_amount_max_quantity:  money_amount_max_quantity
		money_amount_price_list_id: money_amount_price_list_id
		money_amount_region_id:     money_amount_region_id
	}
}

// TODO this sucks. rewrite: fetch money_amount separately with a second query
fn (mut app App) retrieve_product_variant_by_id(id string) !ProductVariant {
	id_bin := id_to_bin(id)!
	mut tx := app.start_transaction()!
	data := tx.execute('SELECT 
		pv.id,
		pv.created_at,
		pv.updated_at,
		pv.deleted_at,
		pv.product_id,
		pv.title,
		pv.sku,
		pv.barcode,
		pv.ean,
		pv.upc,
		pv.variant_rank,
		pv.inventory_quantity,
		pv.allow_backorder,
		pv.manage_inventory,
		pv.hs_code,
		pv.origin_country,
		pv.mid_code,
		pv.weight,
		pv.length,
		pv.height,
		pv.width,
		m.id AS m_id,
		m.created_at AS m_created_at,
		m.updated_at AS m_updated_at,
		m.deleted_at AS m_deleted_at,
		m.currency_code,
		m.amount,
		m.min_quantity,
		m.max_quantity,
		m.price_list_id,
		m.region_id
		FROM product_variant pv
		LEFT JOIN product_variant_money_amount pvma ON pv.id = pvma.variant_id
		LEFT JOIN money_amount m ON pvma.money_amount_id = m.id
		WHERE pv.id = ?',
		id_bin)!

	if data.rows.len == 0 {
		return error('Could not find ProductVariant with the given id')
	}

	// eliminate duplicate rows
	mut parsed_rows := []ProductVariantRow{}
	for i := 0; i < data.rows.len; i++ {
		parsed_row := parse_product_variant_row(data.rows[i].values)!
		parsed_rows = arrays.concat(parsed_rows, parsed_row)
	}

	if parsed_rows.len == 1 {
		money_amount := MoneyAmount{
			id:            parsed_rows[0].money_amount_id
			created_at:    parsed_rows[0].money_amount_created_at
			updated_at:    parsed_rows[0].money_amount_updated_at
			deleted_at:    parsed_rows[0].money_amount_deleted_at
			currency_code: parsed_rows[0].money_amount_currency_code
			amount:        parsed_rows[0].money_amount_amount
			min_quantity:  parsed_rows[0].money_amount_min_quantity
			max_quantity:  parsed_rows[0].money_amount_max_quantity
			price_list_id: parsed_rows[0].money_amount_price_list_id
			region_id:     parsed_rows[0].money_amount_region_id
		}
		return ProductVariant{
			id:                 parsed_rows[0].id
			created_at:         parsed_rows[0].created_at
			updated_at:         parsed_rows[0].updated_at
			deleted_at:         parsed_rows[0].deleted_at
			product_id:         parsed_rows[0].product_id
			sku:                parsed_rows[0].sku
			barcode:            parsed_rows[0].barcode
			ean:                parsed_rows[0].ean
			upc:                parsed_rows[0].upc
			variant_rank:       parsed_rows[0].variant_rank
			inventory_quantity: parsed_rows[0].inventory_quantity
			allow_backorder:    parsed_rows[0].allow_backorder
			manage_inventory:   parsed_rows[0].manage_inventory
			hs_code:            parsed_rows[0].hs_code
			origin_country:     parsed_rows[0].origin_country
			mid_code:           parsed_rows[0].mid_code
			weight:             parsed_rows[0].weight
			length:             parsed_rows[0].length
			height:             parsed_rows[0].height
			width:              parsed_rows[0].width
			title:              parsed_rows[0].title
			money_amounts:      [money_amount]
		}
	}
}

struct NewProductVariantData {
	product_id         string
	sku                string
	barcode            string
	ean                string
	upc                string
	variant_rank       i32
	inventory_quantity i32
	allow_backorder    bool
	manage_inventory   bool
	hs_code            string
	origin_country     string
	mid_code           string
	weight             i32
	length             i32
	height             i32
	width              i32
	title              string
}

struct RetrieveProductVariantParams {
	id                 ZeroArrayString
	allow_backorder    ZeroBool
	manage_inventory   ZeroBool
	region_id          ZeroString
	currency_code      ZeroString // TODO join money_amount on id = ma.variant_id
	title              ZeroString
	inventory_quantity ZeroI32
	offset             ZeroI32
	fetch              ZeroI32
	order              ZeroString
}

fn build_query_retrieve_product_variants(p RetrieveProductVariantParams) !(string, []firebird.Value) {
	base_query := 'SELECT 
		id,
		created_at,
		updated_at,
		deleted_at,
		product_id,
		title,
		sku,
		barcode,
		ean,
		upc,
		variant_rank,
		inventory_quantity,
		allow_backorder,
		manage_inventory,
		hs_code,
		origin_country,
		mid_code,
		weight,
		length,
		height,
		width,
	 	FROM product_variant'

	mut params := []firebird.Value{}

	mut c := []string{}

	if p.id.is_set {
		for i := 0; i < p.id.v.len; i++ {
			id := p.id.v[i]
			params = arrays.concat(params, id)
		}
		c = arrays.concat(c, 'WHERE id IN ${get_n_placeholders(i32(p.id.v.len))}')
	}

	if p.allow_backorder.is_set {
		c = arrays.concat(c, 'WHERE allow_backorder = ?')
		params = arrays.concat(params, p.allow_backorder.v)
	}

	if p.manage_inventory.is_set {
		c = arrays.concat(c, 'WHERE manage_inventory = ?')
		params = arrays.concat(params, p.manage_inventory.v)
	}

	if p.region_id.is_set {
		c = arrays.concat(c, 'WHERE region_id = ?')
		params = arrays.concat(params, p.region_id)
	}

	if p.title.is_set {
		c = arrays.concat(c, 'WHERE title = ?')
		params = arrays.concat(params, p.title)
	}

	if p.inventory_quantity.is_set {
		c = arrays.concat(c, 'WHERE inventory_quantity = ?')
		params = arrays.concat(params, p.inventory_quantity.v)
	}

	mut sorting := ''
	if p.offset.is_set {
		sorting = appendln(sorting, 'OFFSET ? ROWS')
		params = arrays.concat(params, p.offset.v)
	}

	if p.fetch.is_set {
		sorting = appendln(sorting, 'FETCH NEXT ? ROWS ONLY')
		params = arrays.concat(params, p.fetch.v)
	}

	sorting = appendln(sorting, 'ORDER BY product_id ${get_sorting_order(p.order)}')

	return '${base_query}${get_conditions(c)}${sorting}', params
}

fn (mut app App) retrieve_product_variants(p RetrieveProductVariantParams) ![]ProductVariant {
	query, params := build_query_retrieve_product_variants(p)!

	mut tx := app.start_transaction()!
	data := tx.execute(query, ...params)!
	tx.rollback()!

	mut variants := []ProductVariant{}
	for i := 0; i < data.rows.len; i++ {
		variant := parse_product_variant(data.rows[i].values)!
		variants = arrays.concat(variants, variant)
	}
	return variants
}

struct UpdateProductVariantData {
	sku                ?string
	barcode            ?string
	ean                ?string
	upc                ?string
	variant_rank       ?i32
	inventory_quantity ?i32
	allow_backorder    ?bool
	manage_inventory   ?bool
	hs_code            ?string
	origin_country     ?string
	mid_code           ?string
	weight             ?i32
	length             ?i32
	height             ?i32
	width              ?i32
	title              ?string
	// options []
}

fn build_query_update_product_variant(id string, p UpdateProductVariantData) !(string, []firebird.Value) {
	id_bin := id_to_bin(id)!
	mut query := 'UPDATE product_variant SET'
	mut params := []firebird.Value{}

	if sku := p.sku {
		query = appendln(query, 'sku = ?')
		params = arrays.concat(params, sku)
	}

	// TODO continue

	query = appendln(query, 'WHERE id = ?')
	params = arrays.concat(params, id_bin)
	return query, params
}

fn (mut app App) update_product_variant(id string, p UpdateProductVariantData) ! {
	query, params := build_query_update_product_variant(id, p)!
	mut tx := app.start_transaction()!
	tx.execute(query, ...params)!
	tx.commit()!
}

fn (mut app App) do_update_variant_money_amounts(mut tx firebird.Transaction, variant_id string, data []UpdateMoneyAmountData) ! {
	variant_id_bin := id_to_bin(variant_id)!

	// Delete all money_amounts that are not given by the user and that have no related price_list
	mut persisting_ids := []ID{}
	for i := 0; i < data.len; i++ {
		ma := data[i]
		if ma_id := ma.id {
			ma_id_bin := id_to_bin(ma_id)!
			persisting_id := ID{
				s: ma_id
				b: ma_id_bin
			}
			arrays.concat(persisting_ids, persisting_id)
		}
	}

	if persisting_ids.len == 0 {
		tx.execute('DELETE FROM money_amount
		WHERE price_list_id IS NULL
		AND id IN (
			SELECT money_amount_id
			FROM product_variant_money_amount
			WHERE variant_id = ?)',
			variant_id_bin)!
	} else {
		mut persisting_ids_bin := [][]u8{len: persisting_ids.len}
		for i := 0; i < persisting_ids.len; i++ {
			persisting_id_bin := persisting_ids[i].bin()
			persisting_ids_bin[i] = persisting_id_bin
		}

		tx.execute('DELETE FROM money_amount
		WHERE price_list_id IS NULL
		AND id IN (
			SELECT money_amount_id
			FROM product_variant_money_amount
			WHERE variant_id = ?
			AND money_amount_id NOT IN (${get_n_placeholders(i32(persisting_ids_bin.len))}))
	',
			...arrays.concat([variant_id_bin], ...persisting_ids_bin))!
	}

	// TODO inefficient
	// option 1: prepare statements (simple, not the best)
	// option 2: use a complex merge statement (complex, best performance)
	for i := 0; i < data.len; i++ {
		ma := data[i]
		if money_amount_id := ma.id {
			money_amount_id_bin := id_to_bin(money_amount_id)!
			tx.execute('UPDATE money_amount SET amount = ? WHERE id = ?', ma.amount, money_amount_id_bin)!
		} else {
			ma_id := app.new_id()!
			tx.execute('INSERT INTO money_amount (id, currency_code, amount) VALUES (?, ?, ?)',
				ma_id.bin(), ma.currency_code, ma.amount)!
			tx.execute('INSERT INTO product_variant_money_amount (variant_id, money_amount_id)',
				variant_id_bin, ma_id.bin())!
		}
	}
}

// delete any money_amount that is not in the array and that does not have a price_list_id associated with it
// add money_amount that do not yet exist
fn (mut app App) update_variant_money_amounts(variant_id string, data []UpdateMoneyAmountData) ! {
	mut tx := app.start_transaction()!
	app.do_update_variant_money_amounts(mut tx, variant_id, data) or {
		tx.rollback()!
		return err
	}
	tx.commit()!
}
