module peony

import arrays
import einar_hjortdal.firebird

pub const variant_default_title = 'default variant'
pub const option_default_title = 'default option'
pub const option_value_default_name = 'default value'

struct ProductVariant {
	id             string
	id_bin         []u8
	created_at     firebird.DateTime
	updated_at     firebird.DateTime
	deleted_at     firebird.NullDateTime
	product_id     string
	product_id_bin []u8
	title          firebird.NullString
	barcode        firebird.NullString
	ean            firebird.NullString
	upc            firebird.NullString
	variant_rank   i32
	metadata       firebird.NullString
	// image              firebird.NullString // from variant_image TODO
mut:
	inventory_item InventoryItem
	money_amounts  []VariantMoneyAmount
	option_values  []ProductOptionValue
}

struct VariantCreateDefaultWithOptionsParams {
	// TODO
}

// Used in product creation
// Creates options, their translations, their values and translations.
// Then it creates a default variant using the first value of each option.
fn model_variant_create_default_with_options(mut app App, mut tx firebird.Transaction, product_id_bin []u8, variant_id_bin []u8, ph []ProductOptionCreateRequestHygienised) ! {
	mut product_option_ids_bin := [][]u8{len: ph.len}
	mut n_option_translations := 0
	mut n_option_value_translations := 0
	mut n_option_values := 0
	mut first_value_of_option := []i32{len: ph.len}
	for i := 0; i < ph.len; i++ {
		first_value_of_option[i] = n_option_values
		o := ph[i]
		_, product_option_ids_bin[i] = app.new_id()

		if translations := o.translations {
			n_option_translations += translations.len
		}

		n_option_values += o.values.len
		for j := 0; j < o.values.len; j++ {
			ov := o.values[j]
			if translations := ov.translations {
				n_option_value_translations += translations.len
			}
		}
	}

	mut product_option_value_ids_bin := [][]u8{len: n_option_values}
	for i := 0; i < n_option_values; i++ {
		_, product_option_value_ids_bin[i] = app.new_id()
	}

	mut src := []string{len: product_option_ids_bin.len}
	mut params := []firebird.Value{len: product_option_ids_bin.len * 2, init: firebird.Null{}}
	for i := 0; i < product_option_ids_bin.len; i++ {
		src[i] = 'SELECT
			CAST(? AS BINARY(16)) AS product_option_id,
			CAST(? AS BINARY(16)) AS product_id
			FROM RDB\$DATABASE'
		params[i * 2] = product_option_ids_bin[i]
		params[i * 2 + 1] = product_id_bin
	}

	tx.execute('INSERT INTO product_option (id, product_id) ${get_merge_source(src)}',
		...params)!

	src = []string{len: n_option_translations}
	params = []firebird.Value{len: n_option_translations * 3, init: firebird.Null{}}
	mut n_iteration := 0
	for i := 0; i < ph.len; i++ {
		product_option_id_bin := product_option_ids_bin[i]
		if translations := ph[i].translations {
			for j := 0; j < translations.len; j++ {
				translation := translations[j]
				src[n_iteration] = 'SELECT
				CAST(? AS BINARY(16)) AS product_option_id,
				CAST(? AS BINARY(16)) AS locale_id,
				CAST(? AS VARCHAR(63)) AS title
				FROM RDB\$DATABASE'

				params[n_iteration * 3] = product_option_id_bin
				params[n_iteration * 3 + 1] = translation.locale_id_bin
				params[n_iteration * 3 + 2] = translation.title
				n_iteration++
			}
		}
	}

	tx.execute('INSERT INTO product_option_translations (product_option_id, locale_id, title) ${get_merge_source(src)}',
		...params)!

	// product_option_value
	src = []string{len: n_option_values}
	params = []firebird.Value{len: n_option_values * 2, init: firebird.Null{}}
	mut current_value := 0
	for i := 0; i < ph.len; i++ {
		product_option_id_bin := product_option_ids_bin[i]
		product_option_values := ph[i].values
		for j := 0; j < product_option_values.len; j++ {
			product_option_value_id_bin := product_option_value_ids_bin[current_value]
			src[current_value] = 'SELECT
				CAST(? AS BINARY(16)) AS id,
				CAST(? AS BINARY(16)) AS option_id
				FROM RDB\$DATABASE'

			params[current_value * 2] = product_option_value_id_bin
			params[current_value * 2 + 1] = product_option_id_bin

			current_value++
		}
	}

	tx.execute('INSERT INTO product_option_value (id, option_id) ${get_merge_source(src)}',
		...params)!

	// product_option_value_translations
	src = []string{len: n_option_value_translations}
	params = []firebird.Value{len: n_option_value_translations * 3, init: firebird.Null{}}
	current_value = 0
	mut current_translation := 0
	for i := 0; i < ph.len; i++ {
		product_option_values := ph[i].values
		for j := 0; j < product_option_values.len; j++ {
			product_option_value_id_bin := product_option_value_ids_bin[current_value]
			if value_translations := product_option_values[j].translations {
				for k := 0; k < value_translations.len; k++ {
					translation := value_translations[k]
					src[current_translation] = 'SELECT
						CAST(? AS BINARY(16)) AS product_option_value_id,
						CAST(? AS BINARY(16)) AS locale_id,
						CAST(? AS VARCHAR(63)) AS name
						FROM RDB\$DATABASE'
					params[current_translation * 3] = product_option_value_id_bin
					params[current_translation * 3 + 1] = translation.locale_id_bin
					params[current_translation * 3 + 2] = translation.name

					current_translation++
				}
			}

			current_value++
		}
	}

	tx.execute('INSERT INTO product_option_value_translations
		(product_option_value_id, locale_id, name) ${get_merge_source(src)}',
		...params)!

	tx.execute('INSERT INTO product_variant (id, product_id, title) VALUES (?, ?, ?)',
		variant_id_bin, product_id_bin, variant_default_title)!

	_, inventory_item_id_bin := app.new_id()
	tx.execute('INSERT INTO inventory_item (id, variant_id) VALUES (?, ?)', inventory_item_id_bin,
		variant_id_bin)!

	// relations to new product_variant
	// give the variant the first value of each option
	src = []string{len: ph.len}
	params = []firebird.Value{len: ph.len * 2, init: firebird.Null{}}
	for i := 0; i < ph.len; i++ {
		src[i] = 'SELECT
			CAST(? AS BINARY(16)) AS option_value_id,
			CAST(? AS BINARY(16)) AS variant_id
			FROM RDB\$DATABASE'
		first_value_index := first_value_of_option[i]
		params[i * 2] = product_option_value_ids_bin[first_value_index]
		params[i * 2 + 1] = variant_id_bin
	}

	tx.execute('INSERT INTO product_option_value_product_variant (option_value_id, variant_id)
		${get_merge_source(src)}',
		...params)!
}

struct VariantCreateDefaultParams {
	product_id_bin        []u8
	variant_id_bin        []u8
	option_id_bin         []u8
	option_value_id_bin   []u8
	inventory_item_id_bin []u8
}

fn model_variant_create_default(mut tx firebird.Transaction, p VariantCreateDefaultParams) ! {
	tx.execute('INSERT INTO product_option (id, product_id, title) VALUES (?, ?, ?)',
		p.option_id_bin, p.product_id_bin, option_default_title)!

	tx.execute('INSERT INTO product_option_value (id, option_id, name) VALUES (?, ?, ?)',
		p.option_value_id_bin, p.option_id_bin, option_value_default_name)!

	tx.execute('INSERT INTO product_variant (id, product_id, title) VALUES (?, ?, ?)',
		p.variant_id_bin, p.product_id_bin, variant_default_title)!

	tx.execute('INSERT INTO inventory_item (id, variant_id) VALUES (?, ?)', p.inventory_item_id_bin,
		p.variant_id_bin)!

	tx.execute('INSERT INTO product_option_value_product_variant (option_value_id, variant_id)
		VALUES (?, ?)',
		p.option_value_id_bin, p.variant_id_bin)!
}

fn model_product_variants_retrieve_conditions(p RetrieveProductVariantParamsHygienised) (string, []firebird.Value) {
	mut params := []firebird.Value{}
	mut conditions := []string{}

	if p.ids.is_set {
		conditions = arrays.concat(conditions, 'id IN (${get_placeholders(p.ids_bin)})')
		params = arrays.concat(params, ...workaround_24757(p.ids_bin))
	}

	if p.product_ids.is_set {
		conditions = arrays.concat(conditions, 'product_id IN (${get_placeholders(p.product_ids_bin)})')
		params = arrays.concat(params, ...workaround_24757(p.product_ids_bin))
	}

	if p.allow_backorder.is_set {
		conditions = arrays.concat(conditions, 'allow_backorder = ?')
		params = arrays.concat(params, p.allow_backorder.v)
	}

	// TODO handle correctly
	// if p.region_id.is_set {
	// 	c = arrays.concat(c, 'region_id = ?')
	// 	params = arrays.concat(params, p.region_id)
	// }

	if !p.with_deleted.is_set || (p.with_deleted.is_set && !p.with_deleted.v) {
		conditions = arrays.concat(conditions, 'deleted_at IS NULL')
	}

	return get_where_conditions(conditions), params
}

fn model_product_variants_retrieve_count(mut tx firebird.Transaction, p RetrieveProductVariantParamsHygienised) !i64 {
	conditions, mut params := model_product_variants_retrieve_conditions(p)
	data := tx.execute('SELECT COUNT(*) FROM product_variant ${conditions}', ...params)!
	rows := data.rows()
	values := rows[0].values() // should always return one row
	count, _ := values[0].get_i64()! // should always return one column
	return count
}

fn model_product_variants_retrieve(mut tx firebird.Transaction, p RetrieveProductVariantParamsHygienised) ![]ProductVariant {
	conditions, mut params := model_product_variants_retrieve_conditions(p)
	mut sorting := 'ORDER BY product_id, variant_rank ${get_sorting_order(p.order)}'

	if p.offset.is_set {
		sorting = appendln(sorting, 'OFFSET ? ROWS')
		params = arrays.concat(params, p.offset.v)
	}

	if p.fetch.is_set {
		sorting = appendln(sorting, 'FETCH NEXT ? ROWS ONLY')
		params = arrays.concat(params, p.fetch.v)
	}

	data := tx.execute('SELECT 
		id,
		created_at,
		updated_at,
		deleted_at,
		product_id,
		title,
		barcode,
		ean,
		upc,
		variant_rank,
		metadata
		FROM product_variant
		${conditions}
		${sorting}',
		...params)!
	rows := data.rows()

	// exit early if no rows returned
	if rows.len == 0 {
		return []ProductVariant{}
	}

	mut variants := []ProductVariant{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()

		id_bin, _ := v[0].get_array_u8()!
		created_at, _ := v[1].get_date_time()!
		updated_at, _ := v[2].get_date_time()!
		deleted_at := v[3].get_null_date_time()!
		product_id_bin, _ := v[4].get_array_u8()!
		title := v[5].get_null_string()!
		barcode := v[6].get_null_string()!
		ean := v[7].get_null_string()!
		upc := v[8].get_null_string()!
		variant_rank, _ := v[9].get_i32()!
		metadata := v[10].get_null_string()!

		id := id_bin_to_string(id_bin)!
		product_id := id_bin_to_string(product_id_bin)!

		variants[i] = ProductVariant{
			id:             id
			id_bin:         id_bin
			created_at:     created_at
			updated_at:     updated_at
			deleted_at:     deleted_at
			product_id:     product_id
			product_id_bin: product_id_bin
			title:          title
			barcode:        barcode
			ean:            ean
			upc:            upc
			variant_rank:   variant_rank
			metadata:       metadata
		}
	}
	return variants
}

fn model_product_variants_retrieve_by_ids(mut tx firebird.Transaction, variant_ids_bin [][]u8) ![]ProductVariant {
	vph := RetrieveProductVariantParamsHygienised{
		ids:     ZeroArrayString{
			is_set: true
		}
		ids_bin: variant_ids_bin
	}
	return model_product_variants_retrieve(mut tx, vph)
}

fn model_product_variants_retrieve_by_product_ids(mut tx firebird.Transaction, product_ids_bin [][]u8) ![]ProductVariant {
	vph := RetrieveProductVariantParamsHygienised{
		product_ids:     ZeroArrayString{
			is_set: true
		}
		product_ids_bin: product_ids_bin
	}
	return model_product_variants_retrieve(mut tx, vph)
}

fn model_product_variant_create(mut tx firebird.Transaction, product_id_bin []u8, variant_id_bin []u8, ph VariantCreateRequestHygienised) ! {
	mut columns := ['id', 'product_id']
	mut params := [firebird.Value(variant_id_bin), product_id_bin]
	if title := ph.title {
		columns = arrays.concat(columns, 'title')
		params = arrays.concat(params, title)
	}

	if barcode := ph.barcode {
		columns = arrays.concat(columns, 'barcode')
		params = arrays.concat(params, barcode)
	}

	if ean := ph.ean {
		columns = arrays.concat(columns, 'ean')
		params = arrays.concat(params, ean)
	}

	if upc := ph.upc {
		columns = arrays.concat(columns, 'upc')
		params = arrays.concat(params, upc)
	}

	if metadata := ph.metadata {
		columns = arrays.concat(columns, 'metadata')
		params = arrays.concat(params, metadata)
	}

	tx.execute('INSERT INTO product_variant (${get_columns(columns)}) 
		VALUES (${get_placeholders(columns)})',
		...params)!
}

fn model_product_variant_update(mut tx firebird.Transaction, variant_id_bin []u8, ph VariantUpdateRequestHygienised) ! {
	mut columns := []string{}
	mut params := []firebird.Value{}

	if title := ph.title {
		columns = arrays.concat(columns, 'title')
		params = arrays.concat(params, title)
	}

	if barcode := ph.barcode {
		columns = arrays.concat(columns, 'barcode')
		params = arrays.concat(params, barcode)
	}

	if ean := ph.ean {
		columns = arrays.concat(columns, 'ean')
		params = arrays.concat(params, ean)
	}

	if upc := ph.upc {
		columns = arrays.concat(columns, 'upc')
		params = arrays.concat(params, upc)
	}

	if metadata := ph.metadata {
		columns = arrays.concat(columns, 'metadata')
		params = arrays.concat(params, metadata)
	}

	params = arrays.concat(params, variant_id_bin)

	tx.execute('UPDATE product_variant ${get_set_columns_with_updated_at(columns)} WHERE id = ?',
		...params)!
}

fn model_product_variant_delete(mut tx firebird.Transaction, variant_id_bin []u8) ! {
	tx.execute('UPDATE product_variant SET deleted_at = CURRENT_TIMESTAMP WHERE id = ?',
		variant_id_bin)!
}

fn model_product_variant_product_option_value_update(mut tx firebird.Transaction)
