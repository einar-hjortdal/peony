module peony

import arrays
import einar_hjortdal.firebird

struct Variant {
	id                    string
	id_bin                []u8
	created_at            firebird.DateTime
	updated_at            firebird.DateTime
	deleted_at            firebird.NullDateTime
	product_id            string
	product_id_bin        []u8
	inventory_item_id     string
	inventory_item_id_bin []u8
	title                 firebird.NullString
	barcode               firebird.NullString
	ean                   firebird.NullString
	upc                   firebird.NullString
	variant_rank          i32
	metadata              firebird.NullString
	// image              firebird.NullString // from variant_image TODO
mut:
	money_amounts   []MoneyAmount
	option_values   []ProductOptionValue
	inventory_items []InventoryItem
}

fn do_retrieve_product_variant_money_amount(mut tx firebird.Transaction, variants []Variant) ![]MoneyAmount {
	// extract the ids of the retrieved variants to batch fetch money_amounts
	mut ids_bin := [][]u8{len: variants.len}
	for i := 0; i < variants.len; i++ {
		ids_bin[i] = variants[i].id_bin
	}

	data := tx.execute('SELECT
		ma.id,
		ma.currency_code,
		ma.amount,
		ma.min_quantity,
		ma.max_quantity,
		ma.price_list_id,
		ma.region_id,
		pvma.variant_id
		FROM money_amount ma
		JOIN product_variant_money_amount pvma ON pvma.money_amount_id = ma.id
		WHERE pvma.variant_id IN (${get_n_placeholders(i32(ids_bin.len))})',
		...workaround_24757(ids_bin))!

	rows := data.rows()

	mut money_amounts := []MoneyAmount{len: rows.len}
	for i := 0; i < rows.len; i++ {
		money_amounts[i] = parse_money_amount(rows[i].values())!
	}

	return money_amounts
}

fn model_product_variants_retrieve(mut tx firebird.Transaction, p RetrieveProductVariantParamsHygienised) !([]Variant, i64) {
	base_query := 'SELECT 
		id,
		created_at,
		updated_at,
		deleted_at,
		product_id,
		inventory_item_id,
		title,
		barcode,
		ean,
		upc,
		variant_rank,
		metadata,
		COUNT(*) OVER()
		FROM product_variant'

	mut params := []firebird.Value{}

	mut c := []string{}

	if p.ids.is_set {
		c = arrays.concat(c, 'id IN (${get_n_placeholders(i32(p.ids.v.len))})')
		params = arrays.concat(params, ...workaround_24757(p.ids_bin))
	}

	if p.product_ids.is_set {
		c = arrays.concat(c, 'product_id IN (${get_n_placeholders(i32(p.product_ids.v.len))})')
		params = arrays.concat(params, ...workaround_24757(p.product_ids_bin))
	}

	if p.allow_backorder.is_set {
		c = arrays.concat(c, 'allow_backorder = ?')
		params = arrays.concat(params, p.allow_backorder.v)
	}

	// TODO handle correctly
	// if p.region_id.is_set {
	// 	c = arrays.concat(c, 'region_id = ?')
	// 	params = arrays.concat(params, p.region_id)
	// }

	if p.title.is_set {
		c = arrays.concat(c, 'title = ?') // TODO use LIKE
		params = arrays.concat(params, p.title)
	}

	if !p.with_deleted.is_set || (p.with_deleted.is_set && !p.with_deleted.v) {
		c = arrays.concat(c, 'deleted_at IS NULL')
	}

	mut sorting := ''
	sorting = appendln(sorting, 'ORDER BY product_id, variant_rank ${get_sorting_order(p.order)}')

	if p.offset.is_set {
		sorting = appendln(sorting, 'OFFSET ? ROWS')
		params = arrays.concat(params, p.offset.v)
	}

	sorting = appendln(sorting, 'FETCH NEXT ? ROWS ONLY')
	params = arrays.concat(params, get_fetch_amount(p.fetch))

	data := tx.execute('${base_query}${get_where_conditions(c)}${sorting}', ...params)!
	rows := data.rows()

	// exit early if no rows returned
	if rows.len == 0 {
		return []Variant{}, 0
	}

	mut variants := []Variant{len: rows.len}
	mut count := i64(0) // TODO will be 0 if offset bigger than count
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()
		id_bin, _ := v[0].get_array_u8()!
		created_at, _ := v[1].get_date_time()!
		updated_at, _ := v[2].get_date_time()!
		deleted_at := v[3].get_null_date_time()!
		product_id_bin, _ := v[4].get_array_u8()!
		inventory_item_id_bin, _ := v[5].get_array_u8()!
		title := v[6].get_null_string()!
		barcode := v[7].get_null_string()!
		ean := v[8].get_null_string()!
		upc := v[9].get_null_string()!
		variant_rank, _ := v[10].get_i32()!
		metadata := v[11].get_null_string()!

		id := id_bin_to_string(id_bin)!
		product_id := id_bin_to_string(product_id_bin)!
		inventory_item_id := id_bin_to_string(inventory_item_id_bin)!

		variants[i] = Variant{
			id:                    id
			id_bin:                id_bin
			created_at:            created_at
			updated_at:            updated_at
			deleted_at:            deleted_at
			product_id:            product_id
			product_id_bin:        product_id_bin
			inventory_item_id:     inventory_item_id
			inventory_item_id_bin: inventory_item_id_bin
			title:                 title
			barcode:               barcode
			ean:                   ean
			upc:                   upc
			variant_rank:          variant_rank
			metadata:              metadata
		}

		if i == 0 {
			count, _ = v[12].get_i64()!
		}
	}
	values := rows[0].values()
	count, _ = values[22].get_i64()!

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

	return variants, count
}

fn model_product_variants_retrieve_by_product_id(mut tx firebird.Transaction, product_id string, product_id_bin []u8) !([]Variant, i64) {
	vm := {
		'product_ids': product_id
	}
	vp := extract_retrieve_product_variant_params(vm)
	vph := RetrieveProductVariantParamsHygienised{
		product_ids:     vp.product_ids
		product_ids_bin: [product_id_bin]
	}
	return model_product_variants_retrieve(mut tx, vph)
}

fn model_product_variant_create(mut tx firebird.Transaction, product_id_bin []u8, variant_id_bin []u8, p ProductVariantRequest) ! {
	mut columns := ['id', 'product_id']
	mut params := [firebird.Value(variant_id_bin), product_id_bin]
	if title := p.title {
		columns = arrays.concat(columns, 'title')
		params = arrays.concat(params, title)
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

	if metadata := p.metadata {
		columns = arrays.concat(columns, 'metadata')
		params = arrays.concat(params, metadata)
	}

	tx.execute('INSERT INTO product_variant (${get_columns(columns)}) 
		VALUES (${get_n_placeholders(i32(columns.len))})',
		...params)!
}

fn do_update_product_variant(mut tx firebird.Transaction, variant_id_bin []u8, p ProductVariantRequest) ! {
	mut query := 'UPDATE product_variant SET'
	mut columns := []string{}
	mut params := []firebird.Value{}

	if title := p.title {
		columns = arrays.concat(columns, 'title')
		params = arrays.concat(params, title)
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

	if metadata := p.metadata {
		columns = arrays.concat(columns, 'metadata')
		params = arrays.concat(params, metadata)
	}

	query = appendln(query, get_set_columns(columns))
	query = appendln(query, 'WHERE id = ?')
	params = arrays.concat(params, variant_id_bin)

	tx.execute(query, ...params)!
}

// TODO handle region (when region_id is provided, select currency_code from region where id = region_id)
// TODO handle min_amount and max_amount
// TODO merge statement at the end
fn do_update_product_variant_money_amount(mut app App, mut tx firebird.Transaction, variant_id_bin []u8, data []MoneyAmountRequestHygienised) ! {
	// TODO early exit is data.len == 0 (delete all money_amounts)
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
			...workaround_24757(arrays.concat([variant_id_bin], ...persisting_ids_bin)))!
	}

	for i := 0; i < data.len; i++ {
		ma := data[i]
		if ma.id_bin.len != 0 {
			tx.execute('UPDATE money_amount SET amount = ? WHERE id = ?', ma.amount, ma.id_bin)!
		} else {
			_, money_amount_id_bin := app.new_id()
			if ma.region_id_bin.len != 0 {
				tx.execute('INSERT INTO money_amount (id, currency_code, amount, region_id) 
					VALUES (?, (SELECT currency_code FROM region WHERE id = ?), ?, ?)',
					money_amount_id_bin, ma.region_id_bin, ma.amount, ma.region_id_bin)!
			} else if currency_code := ma.currency_code {
				tx.execute('INSERT INTO money_amount (id, currency_code, amount) VALUES (?, ?, ?)',
					money_amount_id_bin, currency_code, ma.amount)!
			}

			tx.execute('INSERT INTO product_variant_money_amount (variant_id, money_amount_id) VALUES (?, ?)',
				variant_id_bin, money_amount_id_bin)!
		}
	}
}

fn model_product_variant_delete(mut tx firebird.Transaction, variant_id_bin []u8) ! {
	tx.execute('UPDATE product_variant SET deleted_at = CURRENT_TIMESTAMP WHERE id = ?',
		variant_id_bin)!
}

fn model_product_variant_product_option_value_update(mut tx firebird.Transaction)
