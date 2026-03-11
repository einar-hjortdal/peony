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

struct VariantCreateParams {
	product_id     string
	product_id_bin []u8
	variant_id     string
	variant_id_bin []u8
	image_id       string // TODO
	image_id_bin   []u8
	title          string
	barcode        string
	ean            string
	upc            string
	metadata       string
	variant_rank   i32
}

// TODO validate struct fields
fn model_variant_create(mut tx firebird.Transaction, p []VariantCreateParams) ! {
	mut src := []string{len: p.len}
	n_params := 9
	mut params := []firebird.Value{len: p.len * n_params, init: firebird.Null{}}

	for i := 0; i < p.len; i++ {
		v := p[i]
		src[i] = 'SELECT
			CAST(? AS BINARY(16)) AS id,
			CAST(? AS BINARY(16)) AS product_id,
			CAST(? AS BINARY(16)) AS image_id,
			CAST(? AS VARCHAR(63)) AS title,
			CAST(? AS VARCHAR(63)) AS barcode,
			CAST(? AS VARCHAR(13)) AS ean,
			CAST(? AS VARCHAR(12)) AS upc,
			CAST(? AS INTEGER) AS variant_rank,
			CAST(? AS BLOB SUB_TYPE TEXT) AS metadata
			FROM RDB\$DATABASE'

		params[i * n_params] = v.variant_id_bin
		params[i * n_params + 1] = v.product_id_bin

		if v.image_id_bin.len > 0 {
			params[i * n_params + 2] = v.image_id_bin
		}

		if v.title != '' {
			params[i * n_params + 3] = v.title
		}

		if v.barcode != '' {
			params[i * n_params + 4] = v.barcode
		}

		if v.ean != '' {
			params[i * n_params + 5] = v.ean
		}

		if v.upc != '' {
			params[i * n_params + 6] = v.upc
		}

		params[i * n_params + 7] = v.variant_rank

		if v.metadata != '' {
			params[i * n_params + 8] = v.metadata
		}
	}

	tx.execute('INSERT INTO product_variant
		(
			id,
			product_id,
			image_id,
			title,
			barcode,
			ean,
			upc,
			variant_rank,
			metadata
		) (${get_merge_source(src)})',
		...params)!
}

struct VariantUpdateParams {
	id           string
	id_bin       []u8
	image_id     string
	image_id_bin []u8
	title        string
	barcode      string
	ean          string
	upc          string
	variant_rank i32
	metadata     string
}

fn model_product_variant_update(mut tx firebird.Transaction, product_id_bin []u8, p []VariantUpdateParams) ! {
	mut src := []string{len: p.len}
	n_params := 9
	mut params := []firebird.Value{len: p.len * n_params, init: firebird.Null{}}

	for i := 0; i < p.len; i++ {
		variant := p[i]
		src[i] = 'SELECT
			CAST(? AS BINARY(16)) AS id,
			CAST(? AS BINARY(16)) AS product_id,
			CAST(? AS BINARY(16)) AS image_id,
			CAST(? AS VARCHAR(63)) AS title,
			CAST(? AS VARCHAR(63)) AS barcode,
			CAST(? AS VARCHAR(13)) AS ean,
			CAST(? AS VARCHAR(12)) AS upc,
			CAST(? AS INTEGER) AS variant_rank,
			CAST(? AS BLOB SUB_TYPE TEXT) AS metadata
			FROM RDB\$DATABASE'

		params[i * n_params + 0] = variant.id_bin
		params[i * n_params + 1] = product_id_bin

		if variant.image_id_bin.len > 0 {
			params[i * n_params + 2] = variant.image_id_bin
		}

		if variant.title != '' {
			params[i * n_params + 3] = variant.title
		}

		if variant.barcode != '' {
			params[i * n_params + 4] = variant.barcode
		}

		if variant.ean != '' {
			params[i * n_params + 5] = variant.ean
		}

		if variant.upc != '' {
			params[i * n_params + 6] = variant.upc
		}

		params[i * n_params + 7] = variant.variant_rank
		params[i * n_params + 8] = variant.metadata
	}

	query := 'MERGE INTO product_variant t
		USING (${get_merge_source(src)}) s
		ON s.id = t.id
		WHEN MATCHED THEN UPDATE
			SET
				updated_at = CURRENT_TIMESTAMP,
				image_id = s.image_id,
				title = s.title,
				barcode = s.barcode,
				ean = s.ean,
				upc = s.upc,
				variant_rank = s.variant_rank,
				metadata = s.metadata
		WHEN NOT MATCHED THEN
			INSERT
				(
					id,
					product_id,
					image_id,
					title,
					barcode,
					ean,
					upc,
					variant_rank,
					metadata
				)
			VALUES
				(
					s.id,
					s.product_id,
					s.image_id,
					s.title,
					s.barcode,
					s.ean,
					s.upc,
					s.variant_rank,
					s.metadata
				)
		WHEN NOT MATCHED BY SOURCE
			AND product_id = ? 
			AND deleted_at IS NOT NULL
			THEN UPDATE
				SET deleted_at = CURRENT_TIMESTAMP'

	params = arrays.concat(params, product_id_bin)

	tx.execute(query, ...params)!
}

fn model_product_variant_delete(mut tx firebird.Transaction, variant_id_bin []u8) ! {
	tx.execute('UPDATE product_variant SET deleted_at = CURRENT_TIMESTAMP WHERE id = ?',
		variant_id_bin)!
}
