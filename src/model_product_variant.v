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
	variant_id_bin := id_to_bin(variant_id)!

	// Delete all money_amounts that are not given by the user
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
