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
}

fn parse_product_variant(v []firebird.Value) !ProductVariant {
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

	return ProductVariant{
		id:                 id
		created_at:         created_at
		updated_at:         updated_at
		deleted_at:         deleted_at
		product_id:         product_id
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
		weight:             weight
		length:             length
		height:             height
		width:              width
		title:              title
	}
}

fn (mut app App) retrieve_product_variant_by_id(id string) !ProductVariant {
	id_bin := id_to_bin(id)!
	mut tx := app.start_transaction()!
	data := tx.execute('SELECT 
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
	 	FROM product_variant
		WHERE id = ?',
		id_bin)!

	if data.rows.len == 0 {
		return error('Could not find ProductVariant with the given id')
	}

	return parse_product_variant(data.rows[0].values)
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

struct ProductVariantMoneyAmount {
	variant_id      string
	money_amount_id string
	created_at      firebird.DateTime
	updated_at      firebird.DateTime
	deleted_at      firebird.DateTime @[omitempty]
}

fn parse_product_variant_money_amount(v []firebird.Value) !ProductVariantMoneyAmount {
}

struct UpdateMoneyAmountData {
	id            ?string
	currency_code string
	amount        i32
	min_quantity  ?i32
	max_quantity  ?i32
	price_list_id ?string
	variant_id    ?string
	region_id     ?string
}

fn (mut app App) do_update_variant_money_amounts(mut tx firebird.Transaction, variant_id string, data []UpdateMoneyAmountData) ! {
	mut persisting_money_amounts := []string{}
	for i := 0; i < data.len; i++ {
		ma := data[i]
		if ma_id := ma.id {
			arrays.concat(persisting_money_amounts, ma_id)
		}
	}
	mut money_amount_to_prune := []string{}

	variant_id_bin := id_to_bin(variant_id)!
	current_data := tx.execute('SELECT 
		variant_id,
		money_amount_id,
		created_at,
		updated_at,
		deleted_at
		FROM product_variant_money_amount WHERE variant_id = ?',
		variant_id_bin)!

	if current_data.rows.len == 0 && persisting_money_amounts.len > 0 {
		return error('Provided money_amount id is not related to variant')
	}

	// If there already exist some relation, prune the relations that do not need to persist.
	if current_data.rows.len > 0 {
		mut product_variant_money_amounts := []ProductVariantMoneyAmount{}
		for i := 0; i < current_data.rows.len; i++ {
			values := current_data.rows[i].values
			product_variant_money_amount := parse_product_variant_money_amount(values)!
			product_variant_money_amounts = arrays.concat(product_variant_money_amounts,
				product_variant_money_amount)
		}

		for i := 0; i < product_variant_money_amounts.len; i++ {
			money_amount_id := product_variant_money_amounts[i].money_amount_id
			if money_amount_id !in persisting_money_amounts {
				arrays.concat(money_amount_to_prune, money_amount_id)
			}
		}

		if money_amount_to_prune.len > 0 {
			mut stmt := tx.prepare('DELETE FROM money_amount WHERE id = ? AND price_list_id IS NULL')!
			for i := 0; i < money_amount_to_prune.len; i++ {
				money_amount_id_bin := id_to_bin(money_amount_to_prune[i])!
				stmt.execute(money_amount_id_bin)!
			}
			stmt.close()!
		}
	}

	for i := 0; i < data.len; i++ {
		ma := data[i]
		if money_amount_id := ma.id {
			if money_amount_id !in money_amount_to_prune {
				money_amount_id_bin := id_to_bin(money_amount_id)!
				tx.execute('UPDATE money_amount SET amount = ? WHERE id = ?', ma.amount,
					money_amount_id_bin)!
			}
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
	mut tx := app.start_transaction()!
	app.do_update_variant_money_amounts(mut tx, variant_id, data) or {
		tx.rollback()!
		return err
	}
	tx.commit()!
}
