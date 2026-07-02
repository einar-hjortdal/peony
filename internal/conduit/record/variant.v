module record

import arrays
import einar_hjortdal.firebird
import common

pub const variant_default_title = 'default variant'
pub const option_default_title = 'default option'
pub const option_value_default_name = 'default value'

pub struct Variant {
pub:
	id           ID
	created_at   firebird.DateTime
	updated_at   firebird.DateTime
	deleted_at   ?firebird.DateTime
	product_id   ID
	image_id     ?ID
	title        ?string
	barcode      ?string
	ean          ?string
	upc          ?string
	variant_rank i32
	metadata     ?string
pub mut:
	inventory_item InventoryItem
	money_amounts  []VariantMoneyAmount
	option_values  []ProductOptionValue
}

pub fn (v Variant) id() ID {
	return v.id
}

pub struct VariantRetrieveParams {
pub:
	ids             ?[]ID
	product_ids     ?[]ID
	allow_backorder ?bool
	with_deleted    bool
	offset          i32
	fetch           i32
	order           string
}

pub fn variant_retrieve_conditions(p VariantRetrieveParams) (string, []firebird.Value) {
	mut params := []firebird.Value{}
	mut conditions := []string{}

	if ids := p.ids {
		conditions = arrays.concat(conditions, 'id IN (${get_placeholders(ids)})')
		params = arrays.concat(params, ...ids_bytes(ids))
	}

	if product_ids := p.product_ids {
		conditions = arrays.concat(conditions, 'product_id IN (${get_placeholders(product_ids)})')
		params = arrays.concat(params, ...ids_bytes(product_ids))
	}

	if allow_backorder := p.allow_backorder {
		conditions = arrays.concat(conditions, 'allow_backorder = ?')
		params = arrays.concat(params, allow_backorder)
	}

	if !p.with_deleted {
		conditions = arrays.concat(conditions, 'c.deleted_at is NULL')
	}

	return get_where_conditions(conditions), params
}

pub fn variant_retrieve_count(mut tx firebird.ClientTransaction, p VariantRetrieveParams) !i64 {
	conditions, mut params := variant_retrieve_conditions(p)
	data := tx.execute('SELECT COUNT(*) FROM variant ${conditions}', ...params)!
	rows := data.rows()
	values := rows[0].values() // should always return one row
	count, _ := values[0].get_i64()! // should always return one column
	return count
}

pub fn variant_retrieve(mut tx firebird.ClientTransaction, p VariantRetrieveParams) ![]Variant {
	conditions, mut params := variant_retrieve_conditions(p)

	mut sorting := 'ORDER BY variant_rank ${p.order}
		OFFSET ? ROWS
		FETCH NEXT ? ROWS ONLY'
	params = arrays.concat(params, p.offset, p.fetch)

	query := 'SELECT 
		id,
		created_at,
		updated_at,
		deleted_at,
		product_id,
		image_id,
		title,
		barcode,
		ean,
		upc,
		variant_rank,
		metadata
		FROM variant
		${conditions}
		${sorting}'

	data := tx.execute(query, ...params)!
	rows := data.rows()

	mut variants := []Variant{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()

		id_bin, _ := v[0].get_array_u8()!
		created_at, _ := v[1].get_date_time()!
		updated_at, _ := v[2].get_date_time()!
		deleted_at := v[3].get_null_date_time()!
		product_id_bin, _ := v[4].get_array_u8()!
		image_id_bin, image_id_is_null := v[5].get_array_u8()!
		title := v[6].get_null_string()!
		barcode := v[7].get_null_string()!
		ean := v[8].get_null_string()!
		upc := v[9].get_null_string()!
		variant_rank, _ := v[10].get_i32()!
		metadata := v[11].get_null_string()!

		id := id_from_bytes(id_bin)!
		product_id := id_from_bytes(product_id_bin)!

		mut image_id := ?ID(none)
		if !image_id_is_null {
			image_id = id_from_bytes(image_id_bin)!
		}

		variants[i] = Variant{
			id:           id
			created_at:   created_at
			updated_at:   updated_at
			deleted_at:   deleted_at.none_value()
			product_id:   product_id
			image_id:     image_id
			title:        title.none_value()
			barcode:      barcode.none_value()
			ean:          ean.none_value()
			upc:          upc.none_value()
			variant_rank: variant_rank
			metadata:     metadata.none_value()
		}
	}
	return variants
}

pub struct VariantCreateParams {
pub:
	id           ID
	product_id   ID
	title        ?string
	barcode      ?string
	ean          ?string
	upc          ?string
	metadata     ?string
	variant_rank ?i32
}

// TODO validate struct fields
pub fn variant_create(mut tx firebird.ClientTransaction, p []VariantCreateParams) ! {
	mut src := []string{len: p.len}
	n_params := 9
	mut params := []firebird.Value{len: p.len * n_params, init: firebird.Null{}}

	for i := 0; i < p.len; i++ {
		v := p[i]
		src[i] = 'SELECT
			CAST(? AS BINARY(16)) AS id,
			CAST(? AS BINARY(16)) AS product_id,
			CAST(? AS VARCHAR(63)) AS title,
			CAST(? AS VARCHAR(63)) AS barcode,
			CAST(? AS VARCHAR(13)) AS ean,
			CAST(? AS VARCHAR(12)) AS upc,
			CAST(? AS INTEGER) AS variant_rank,
			CAST(? AS BLOB SUB_TYPE TEXT) AS metadata
			FROM RDB\$DATABASE'

		params[i * n_params] = v.id.bytes()
		params[i * n_params + 1] = v.product_id.bytes()

		if title := v.title {
			if title != '' {
				params[i * n_params + 2] = title
			}
		}

		if barcode := v.barcode {
			if barcode != '' {
				params[i * n_params + 3] = barcode
			}
		}

		if ean := v.ean {
			if ean != '' {
				params[i * n_params + 4] = ean
			}
		}

		if upc := v.upc {
			if upc != '' {
				params[i * n_params + 5] = upc
			}
		}

		if variant_rank := v.variant_rank {
			params[i * n_params + 6] = variant_rank
		} else {
			params[i * n_params + 6] = common.variant_rank_default
		}

		if metadata := v.metadata {
			if metadata != '' {
				params[i * n_params + 7] = metadata
			}
		}
	}

	query := 'INSERT INTO variant
		(
			id,
			product_id,
			title,
			barcode,
			ean,
			upc,
			variant_rank,
			metadata
		) (${get_merge_source(src)})'

	tx.execute(query, ...params)!
}

pub struct VariantUpdateParams {
pub:
	id           ID
	product_id   ID
	title        ?string
	barcode      ?string
	ean          ?string
	upc          ?string
	variant_rank ?i32
	metadata     ?string
}

pub fn variant_update(mut tx firebird.ClientTransaction, p VariantUpdateParams) ! {
	columns := [
		'title',
		'barcode',
		'ean',
		'upc',
		'variant_rank',
		'metadata',
	]

	n_params := 8
	mut params := []firebird.Value{len: n_params, init: firebird.Null{}}

	if title := p.title {
		if title != '' {
			params[0] = title
		}
	}

	if barcode := p.barcode {
		if barcode != '' {
			params[1] = barcode
		}
	}

	if ean := p.ean {
		if ean != '' {
			params[2] = ean
		}
	}

	if upc := p.upc {
		if upc != '' {
			params[3] = upc
		}
	}

	if variant_rank := p.variant_rank {
		params[4] = variant_rank
	}

	if metadata := p.metadata {
		if metadata != '' {
			params[5] = metadata
		}
	}

	params[6] = p.id.bytes()

	query := 'UPDATE variant SET ${get_set_columns(columns)} WHERE id = ?'

	tx.execute(query, ...params)!
}

pub fn product_variant_update(mut tx firebird.ClientTransaction, product_id ID, p []VariantUpdateParams) ! {
	mut src := []string{len: p.len}
	n_params := 9
	mut params := []firebird.Value{len: p.len * n_params, init: firebird.Null{}}

	for i := 0; i < p.len; i++ {
		v := p[i]
		src[i] = 'SELECT
			CAST(? AS BINARY(16)) AS id,
			CAST(? AS BINARY(16)) AS product_id,
			CAST(? AS VARCHAR(63)) AS title,
			CAST(? AS VARCHAR(63)) AS barcode,
			CAST(? AS VARCHAR(13)) AS ean,
			CAST(? AS VARCHAR(12)) AS upc,
			CAST(? AS INTEGER) AS variant_rank,
			CAST(? AS BLOB SUB_TYPE TEXT) AS metadata
			FROM RDB\$DATABASE'

		params[i * n_params + 0] = v.id.bytes()
		params[i * n_params + 1] = v.product_id.bytes()

		if title := v.title {
			if title != '' {
				params[i * n_params + 2] = title
			}
		}

		if barcode := v.barcode {
			if barcode != '' {
				params[i * n_params + 3] = barcode
			}
		}

		if ean := v.ean {
			if ean != '' {
				params[i * n_params + 4] = ean
			}
		}

		if upc := v.upc {
			if upc != '' {
				params[i * n_params + 5] = upc
			}
		}

		if variant_rank := v.variant_rank {
			params[i * n_params + 6] = variant_rank
		} else {
			params[i * n_params + 6] = common.variant_rank_default
		}

		if metadata := v.metadata {
			params[i * n_params + 7] = metadata
		}
	}

	query := 'MERGE INTO variant t
		USING (${get_merge_source(src)}) s
		ON s.id = t.id AND s.product_id = t.product_id
		WHEN MATCHED THEN UPDATE
			SET
				updated_at = CURRENT_TIMESTAMP,
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
					s.title,
					s.barcode,
					s.ean,
					s.upc,
					s.variant_rank,
					s.metadata
				)
		WHEN NOT MATCHED BY SOURCE
			AND product_id = ? 
			AND deleted_at IS NULL
			THEN UPDATE
				SET deleted_at = CURRENT_TIMESTAMP'

	params = arrays.concat(params, product_id.bytes())

	tx.execute(query, ...params)!

	tx.execute('MERGE INTO inventory_item t
		USING
			(
				SELECT 
					id AS variant_id,
					deleted_at
				FROM variant
				WHERE product_id = ?
					AND deleted_at IS NOT NULL
			) s
		ON s.variant_id = t.variant_id
		WHEN MATCHED AND t.deleted_at IS NULL THEN UPDATE 
			SET t.deleted_at = s.deleted_at',
		product_id.bytes())!
}

pub fn variant_delete(mut tx firebird.ClientTransaction, variant_id ID) ! {
	tx.execute('UPDATE variant SET deleted_at = CURRENT_TIMESTAMP WHERE id = ?', variant_id.bytes())!
	tx.execute('UPDATE inventory_item SET deleted_at = CURRENT_TIMESTAMP WHERE variant_id = ?',
		variant_id.bytes())!
}

pub struct VariantImage {
pub:
	variant_id ID
	image_id   ID
}

pub fn variant_image_update(mut tx firebird.ClientTransaction, p []VariantImage) ! {
	mut src := []string{len: 0, cap: p.len}
	mut params := []firebird.Value{len: 0, cap: 2 * p.len, init: firebird.Null{}}
	for _, relation in p {
		src << 'SELECT
			CAST(? AS BINARY(16)) AS id,
			CAST(? AS BINARY(16)) AS image_id
			FROM RDB\$DATABASE'

		params << relation.variant_id.bytes()
		params << relation.image_id.bytes()
	}

	query := 'MERGE INTO variant t
		USING (${get_merge_source(src)}) s (id, image_id)
		ON t.id = s.id
		WHEN MATCHED THEN UPDATE
			SET t.image_id = s.image_id'

	tx.execute(query, ...params)!
}
