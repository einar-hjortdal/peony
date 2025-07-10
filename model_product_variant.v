module main

import arrays
import einar_hjortdal.firebird

struct Variant {
	id                 string
	id_bin             []u8
	created_at         firebird.DateTime
	updated_at         firebird.DateTime
	deleted_at         firebird.DateTime
	product_id         string
	product_id_bin     []u8
	title              string
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
	material           string
	weight             i32
	length             i32
	height             i32
	width              i32
	// image              string // from variant_image TODO
mut:
	money_amounts []MoneyAmount
	option_values []ProductOptionValue
}

fn parse_variant(v []firebird.Value) !Variant {
	id_bin, _ := v[0].get_array_u8()!
	created_at, _ := v[1].get_date_time()!
	updated_at, _ := v[2].get_date_time()!
	deleted_at, _ := v[3].get_date_time()!
	product_id_bin, _ := v[4].get_array_u8()!
	title, _ := v[5].get_string()!
	sku, _ := v[6].get_string()!
	barcode, _ := v[7].get_string()!
	ean, _ := v[8].get_string()!
	upc, _ := v[9].get_string()!
	variant_rank, _ := v[10].get_i32()!
	inventory_quantity, _ := v[11].get_i32()!
	allow_backorder, _ := v[12].get_bool()!
	manage_inventory, _ := v[13].get_bool()!
	hs_code, _ := v[14].get_string()!
	origin_country, _ := v[15].get_string()!
	mid_code, _ := v[16].get_string()!
	material, _ := v[17].get_string()!
	weight, _ := v[18].get_i32()!
	length, _ := v[19].get_i32()!
	height, _ := v[20].get_i32()!
	width, _ := v[21].get_i32()!

	id := id_bin_to_string(id_bin)!
	product_id := id_bin_to_string(product_id_bin)!

	return Variant{
		id:                 id
		id_bin:             id_bin
		created_at:         created_at
		updated_at:         updated_at
		deleted_at:         deleted_at
		product_id:         product_id
		product_id_bin:     product_id_bin
		title:              title
		sku:                sku
		barcode:            barcode
		ean:                ean
		upc:                upc
		variant_rank:       variant_rank
		inventory_quantity: inventory_quantity
		allow_backorder:    allow_backorder
		manage_inventory:   manage_inventory
		hs_code:            hs_code
		origin_country:     origin_country
		mid_code:           mid_code
		material:           material
		weight:             weight
		length:             length
		height:             height
		width:              width
	}
}

struct RetrieveVariantParams {
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

fn extract_retrieve_variant_params(m map[string]string) RetrieveVariantParams {
	return RetrieveVariantParams{
		id:                 zero_array_string(m, 'id')
		allow_backorder:    zero_bool(m, 'allow_backorder')
		manage_inventory:   zero_bool(m, 'manage_inventory')
		region_id:          zero_string(m, 'region_id')
		currency_code:      zero_string(m, 'currency_code')
		title:              zero_string(m, 'title')
		inventory_quantity: zero_i32(m, 'inventory_quantity')
		offset:             zero_i32(m, 'offset')
		fetch:              zero_i32(m, 'fetch')
		order:              zero_string(m, 'order')
	}
}

fn build_query_retrieve_product_variants(p RetrieveVariantParams) !(string, []firebird.Value) {
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
		material,
		weight,
		length,
		height,
		width
		FROM product_variant'

	mut params := []firebird.Value{}

	mut c := []string{}

	if p.id.is_set {
		for i := 0; i < p.id.v.len; i++ {
			id := p.id.v[i]
			id_bin := id_string_to_bin(id)!
			params = arrays.concat(params, id_bin)
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
	sorting = appendln(sorting, 'ORDER BY product_id, variant_rank ${get_sorting_order(p.order)}')

	if p.offset.is_set {
		sorting = appendln(sorting, 'OFFSET ? ROWS')
		params = arrays.concat(params, p.offset.v)
	}

	sorting = appendln(sorting, 'FETCH NEXT ? ROWS ONLY')
	params = arrays.concat(params, get_fetch_amount(p.fetch))

	return '${base_query}${get_conditions(c)}${sorting}', params
}

fn do_retrieve_product_variant_money_amount(mut tx firebird.Transaction, variants []Variant) ![]MoneyAmount {
	// extract the ids of the retrieved variants to batch fetch money_amounts
	mut ids_bin := [][]u8{len: variants.len}
	for i := 0; i < variants.len; i++ {
		ids_bin[i] = variants[i].id_bin
	}

	money_amounts_data := tx.execute('SELECT
		ma.id,
		ma.created_at,
		ma.updated_at,
		ma.deleted_at,
		ma.currency_code,
		ma.amount,
		ma.min_quantity,
		ma.max_quantity,
		ma.price_list_id,
		ma.region_id,
		ma.variant_id
		FROM money_amount ma
		JOIN product_variant_money_amount pvma ON pvma.money_amount_id = ma.id
		WHERE pvma.variant_id IN (${get_n_placeholders(i32(ids_bin.len))})',
		...workaround_24757(ids_bin))!

	mut money_amounts := []MoneyAmount{len: money_amounts_data.rows.len}
	for i := 0; i < money_amounts_data.rows.len; i++ {
		money_amounts[i] = parse_money_amount(money_amounts_data.rows[i].values)!
	}

	return money_amounts
}

fn do_retrieve_product_variants(mut tx firebird.Transaction, p RetrieveVariantParams) ![]Variant {
	query, params := build_query_retrieve_product_variants(p)!
	data := tx.execute(query, ...params)!

	// exit early if no rows returned
	if data.rows.len == 0 {
		return []Variant{}
	}

	mut variants := []Variant{len: data.rows.len}
	for i := 0; i < data.rows.len; i++ {
		variants[i] = parse_variant(data.rows[i].values)!
	}

	// TODO variant_image
	// TODO product_option_value, product_option_value_translations
	// TODO product_variant_inventory_item

	money_amounts := do_retrieve_product_variant_money_amount(mut tx, variants)!

	for i := 0; i < variants.len; i++ {
		for k := 0; k < money_amounts.len; k++ {
			if variants[i].id_bin == money_amounts[k].variant_id_bin.value {
				variants[i].money_amounts = arrays.concat(variants[i].money_amounts, money_amounts[k])
			}
		}
	}

	return variants
}

fn (mut app App) retrieve_product_variants(p RetrieveVariantParams) ![]Variant {
	mut tx := app.start_transaction()!
	variants := do_retrieve_product_variants(mut tx, p) or {
		tx.rollback()!
		return err
	}

	tx.rollback()!
	return variants
}

fn (mut app App) retrieve_product_variant_by_id(variant_id string) !Variant {
	m := {
		'id': variant_id
	}
	p := extract_retrieve_variant_params(m)

	mut tx := app.start_transaction()!
	variants := app.retrieve_product_variants(p) or {
		tx.rollback()!
		return err
	}
	tx.rollback()!

	if variants.len == 0 {
		return error('No variant found with the given id')
	}

	return variants[0]
}

fn (mut app App) do_create_product_variant(mut tx firebird.Transaction, product_id_bin []u8, id_bin []u8, p ProductVariantRequest) ! {
	mut columns := ['id', 'product_id']
	mut params := [firebird.Value(id_bin), product_id_bin]
	if title := p.title {
		columns = arrays.concat(columns, 'title')
		params = arrays.concat(params, title)
	}

	if sku := p.sku {
		columns = arrays.concat(columns, 'sku')
		params = arrays.concat(params, sku)
	}

	if barcode := p.barcode {
		columns = arrays.concat(columns, 'barcode')
		params = arrays.concat(params, barcode)
	}

	if ean := p.ean {
		columns = arrays.concat(columns, 'ean')
		params = arrays.concat(params, ean)
	}

	if upc := p.upc {
		columns = arrays.concat(columns, 'upc')
		params = arrays.concat(params, upc)
	}

	if variant_rank := p.variant_rank {
		columns = arrays.concat(columns, 'variant_rank')
		params = arrays.concat(params, variant_rank)
	}

	if inventory_quantity := p.inventory_quantity {
		columns = arrays.concat(columns, 'inventory_quantity')
		params = arrays.concat(params, inventory_quantity)
	}

	if allow_backorder := p.allow_backorder {
		columns = arrays.concat(columns, 'allow_backorder')
		params = arrays.concat(params, allow_backorder)
	}

	if manage_inventory := p.manage_inventory {
		columns = arrays.concat(columns, 'manage_inventory')
		params = arrays.concat(params, manage_inventory)
	}

	if hs_code := p.hs_code {
		columns = arrays.concat(columns, 'hs_code')
		params = arrays.concat(params, hs_code)
	}

	if origin_country := p.origin_country {
		columns = arrays.concat(columns, 'origin_country')
		params = arrays.concat(params, origin_country)
	}

	if mid_code := p.mid_code {
		columns = arrays.concat(columns, 'mid_code')
		params = arrays.concat(params, mid_code)
	}

	if weight := p.weight {
		columns = arrays.concat(columns, 'weight')
		params = arrays.concat(params, weight)
	}

	if length := p.length {
		columns = arrays.concat(columns, 'length')
		params = arrays.concat(params, length)
	}

	if height := p.height {
		columns = arrays.concat(columns, 'height')
		params = arrays.concat(params, height)
	}

	if width := p.width {
		columns = arrays.concat(columns, 'width')
		params = arrays.concat(params, width)
	}

	println('INSERT INTO product_variant (${get_columns(columns)}) 
		VALUES (${get_n_placeholders(i32(columns.len))})')
	println(params)
	tx.execute('INSERT INTO product_variant (${get_columns(columns)}) 
		VALUES (${get_n_placeholders(i32(columns.len))})',
		...params)!
}

fn (mut app App) create_product_variant(product_id_bin []u8, p ProductVariantRequest) ! {
	_, id_bin := app.new_id()!
	mut tx := app.start_transaction()!
	app.do_create_product_variant(mut tx, product_id_bin, id_bin, p) or {
		tx.rollback()!
		return err
	}
	// TODO handle p.options
	tx.commit()!
}

// TODO create utility function and refactor
fn do_update_product_variant(mut tx firebird.Transaction, variant_id_bin []u8, p ProductVariantRequest) ! {
	mut query := 'UPDATE product_variant SET'
	mut params := []firebird.Value{}

	if title := p.title {
		query = appendln(query, 'title = ?')
		params = arrays.concat(params, title)
	}

	if sku := p.sku {
		query = appendln(query, 'sku = ?')
		params = arrays.concat(params, sku)
	}

	if barcode := p.barcode {
		query = appendln(query, 'barcode = ?')
		params = arrays.concat(params, barcode)
	}

	if ean := p.ean {
		query = appendln(query, 'ean = ?')
		params = arrays.concat(params, ean)
	}

	if upc := p.upc {
		query = appendln(query, 'upc = ?')
		params = arrays.concat(params, upc)
	}

	if variant_rank := p.variant_rank {
		query = appendln(query, 'variant_rank = ?')
		params = arrays.concat(params, variant_rank)
	}

	if inventory_quantity := p.inventory_quantity {
		query = appendln(query, 'inventory_quantity = ?')
		params = arrays.concat(params, inventory_quantity)
	}

	if allow_backorder := p.allow_backorder {
		query = appendln(query, 'allow_backorder = ?')
		params = arrays.concat(params, allow_backorder)
	}

	if manage_inventory := p.manage_inventory {
		query = appendln(query, 'manage_inventory = ?')
		params = arrays.concat(params, manage_inventory)
	}

	if hs_code := p.hs_code {
		query = appendln(query, 'hs_code = ?')
		params = arrays.concat(params, hs_code)
	}

	if origin_country := p.origin_country {
		query = appendln(query, 'origin_country = ?')
		params = arrays.concat(params, origin_country)
	}

	if mid_code := p.mid_code {
		query = appendln(query, 'mid_code = ?')
		params = arrays.concat(params, mid_code)
	}

	if weight := p.weight {
		query = appendln(query, 'weight = ?')
		params = arrays.concat(params, weight)
	}

	if length := p.length {
		query = appendln(query, 'length = ?')
		params = arrays.concat(params, length)
	}

	if height := p.height {
		query = appendln(query, 'height = ?')
		params = arrays.concat(params, height)
	}

	if width := p.width {
		query = appendln(query, 'width = ?')
		params = arrays.concat(params, width)
	}

	query = appendln(query, 'WHERE id = ?')
	params = arrays.concat(params, variant_id_bin)

	tx.execute(query, ...params)!
}

fn do_update_product_variant_money_amount(mut app App, mut tx firebird.Transaction, variant_id_bin []u8, data []UpdateMoneyAmountData) ! {
	// Delete all money_amounts that are not given by the user and that have no related price_list
	mut persisting_ids := [][]u8{}
	for i := 0; i < data.len; i++ {
		ma := data[i]
		if ma_id_string := ma.id {
			persisting_id := id_string_to_bin(ma_id_string)!
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
			persisting_id_bin := persisting_ids[i]
			persisting_ids_bin[i] = persisting_id_bin
		}

		tx.execute('DELETE FROM money_amount
			WHERE price_list_id IS NULL
			AND id IN (
				SELECT money_amount_id
				FROM product_variant_money_amount
				WHERE variant_id = ?
				AND money_amount_id NOT IN (${get_n_placeholders(i32(persisting_ids_bin.len))}))',
			...arrays.concat([variant_id_bin], ...persisting_ids_bin))!
	}

	for i := 0; i < data.len; i++ {
		ma := data[i]
		if money_amount_id := ma.id {
			money_amount_id_bin := id_string_to_bin(money_amount_id)!
			tx.execute('UPDATE money_amount SET amount = ? WHERE id = ?', ma.amount, money_amount_id_bin)!
		} else {
			_, money_amount_id_bin := app.new_id()!
			tx.execute('INSERT INTO money_amount (id, currency_code, amount) VALUES (?, ?, ?)',
				money_amount_id_bin, ma.currency_code, ma.amount)!
			tx.execute('INSERT INTO product_variant_money_amount (variant_id, money_amount_id)',
				variant_id_bin, money_amount_id_bin)!
		}
	}
}

// delete any money_amount that is not in the array and that does not have a price_list_id associated with it
// add money_amount that do not yet exist
fn (mut app App) update_variant_money_amounts(variant_id string, data []UpdateMoneyAmountData) ! {
	id_bin := id_string_to_bin(variant_id)!
	mut tx := app.start_transaction()!
	do_update_product_variant_money_amount(mut app, mut tx, id_bin, data) or {
		tx.rollback()!
		return err
	}
	tx.commit()!
}
