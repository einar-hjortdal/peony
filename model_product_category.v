module peony

import arrays
import einar_hjortdal.firebird

struct ProductCategoryTranslation {
	product_category_id     string
	product_category_id_bin []u8
	locale_id               string
	locale_id_bin           []u8
	name                    string
}

struct ProductCategory {
	id                     string
	id_bin                 []u8
	created_at             firebird.DateTime
	updated_at             firebird.DateTime
	deleted_at             firebird.NullDateTime
	handle                 string
	is_active              bool
	is_internal            bool
	parent_category_id     string
	parent_category_id_bin firebird.NullArrayU8
	metadata               firebird.NullString
mut:
	translations []ProductCategoryTranslation
}

fn model_product_category_create(mut tx firebird.Transaction, id string, id_bin []u8, ph ProductCategoryRequestHygienised) ! {
	mut columns := ['id']
	mut params := [firebird.Value(id_bin)]

	columns = arrays.concat(columns, 'handle')
	if handle := ph.handle {
		params = arrays.concat(params, handle)
	} else {
		params = arrays.concat(params, id)
	}

	if is_active := ph.is_active {
		columns = arrays.concat(columns, 'is_active')
		params = arrays.concat(params, is_active)
	}

	if is_internal := ph.is_internal {
		columns = arrays.concat(columns, 'is_internal')
		params = arrays.concat(params, is_internal)
	}

	if metadata := ph.metadata {
		columns = arrays.concat(columns, 'metadata')
		params = arrays.concat(params, metadata)
	}

	if _ := ph.parent_category_id {
		columns = arrays.concat(columns, 'parent_category_id')
		params = arrays.concat(params, ph.parent_category_id_bin)
	}

	tx.execute('INSERT INTO product_category (${get_columns(columns)}) 
		VALUES (${get_placeholders(params)})',
		...params)!
}

fn model_product_category_update(mut tx firebird.Transaction, product_category_id_bin []u8, ph ProductCategoryRequestHygienised) ! {
	mut columns := []string{}
	mut params := []firebird.Value{}

	if handle := ph.handle {
		columns = arrays.concat(columns, 'handle')
		params = arrays.concat(params, handle)
	}

	if is_active := ph.is_active {
		columns = arrays.concat(columns, 'is_active')
		params = arrays.concat(params, is_active)
	}

	if is_internal := ph.is_internal {
		columns = arrays.concat(columns, 'is_internal')
		params = arrays.concat(params, is_internal)
	}

	if metadata := ph.metadata {
		columns = arrays.concat(columns, 'metadata')
		params = arrays.concat(params, metadata)
	}

	if _ := ph.parent_category_id {
		columns = arrays.concat(columns, 'parent_category_id')
		params = arrays.concat(params, ph.parent_category_id_bin)
	}

	tx.execute('UPDATE product_category SET ${get_set_columns(columns)} WHERE id = ?',
		...params)!
}

fn model_product_category_get(mut tx firebird.Transaction, ph ProductCategoryParamsRetrieveHygienised) !([]ProductCategory, i64) {
	mut query := ''
	mut conditions := []string{}
	mut params := []firebird.Value{}

	if ph.parent_category_ids.is_set {
		query = appendln(query, 'WITH RECURSIVE descendants (id) AS (
			SELECT id FROM product_category
				WHERE parent_category_id IN (${get_placeholders(ph.parent_category_id_bins)})
			UNION ALL
			SELECT pc.id
				FROM product_category pc JOIN descendants d
				ON pc.parent_category_id = d.id
			)')
		params = arrays.concat(params, ...ph.parent_category_id_bins)
	}

	if ph.ids.is_set {
		conditions = arrays.concat(conditions, 'id IN (${get_placeholders(ph.ids_bin)})')
		params = arrays.concat(params, ...ph.ids_bin)
	}

	if ph.handles.is_set {
		conditions = arrays.concat(conditions, 'handle IN (${get_placeholders(ph.handles.v)})')
		params = arrays.concat(params, ...ph.handles.v)
	}

	if ph.is_active.is_set {
		conditions = arrays.concat(conditions, 'is_active = ?')
		params = arrays.concat(params, ph.is_active.v)
	}

	if ph.is_internal.is_set {
		conditions = arrays.concat(conditions, 'is_internal = ?')
		params = arrays.concat(params, ph.is_internal.v)
	}

	if !ph.with_deleted.is_set || ph.with_deleted.v {
		conditions = arrays.concat(conditions, 'deleted_at IS NOT NULL')
	}

	mut sorting := ''
	sorting = appendln(sorting, 'ORDER BY created_at ${get_sorting_order(ph.order)}')

	if ph.offset.is_set {
		sorting = appendln(sorting, 'OFFSET ? ROWS')
		params = arrays.concat(params, ph.offset.v)
	}

	sorting = appendln(sorting, 'FETCH NEXT ? ROWS ONLY')

	query = appendln(query, 'SELECT
		id,
		created_at,
		updated_at,
		deleted_at,
		handle,
		is_active,
		is_internal,
		parent_category_id,
		metadata,
		COUNT(*) OVER()
		FROM product_category ${get_where_conditions(conditions)}${sorting}')

	data := tx.execute(query, ...params)!

	rows := data.rows()
	mut count := i64(0)

	mut product_categories := []ProductCategory{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()
		id_bin, _ := v[0].get_array_u8()!
		created_at, _ := v[1].get_date_time()!
		updated_at, _ := v[2].get_date_time()!
		deleted_at := v[3].get_null_date_time()!
		handle, _ := v[4].get_string()!
		is_active, _ := v[5].get_bool()!
		is_internal, _ := v[6].get_bool()!
		parent_category_id_bin := v[7].get_null_array_u8()!
		metadata := v[8].get_null_string()!

		id := id_bin_to_string(id_bin)!

		mut parent_category_id := ''
		if !parent_category_id_bin.is_null {
			parent_category_id = id_bin_to_string(parent_category_id_bin.value)!
		}

		product_categories[i] = ProductCategory{
			id:                     id
			id_bin:                 id_bin
			created_at:             created_at
			updated_at:             updated_at
			deleted_at:             deleted_at
			handle:                 handle
			is_active:              is_active
			is_internal:            is_internal
			parent_category_id:     parent_category_id
			parent_category_id_bin: parent_category_id_bin
			metadata:               metadata
		}

		if i == 0 {
			count, _ = v[9].get_i64()!
		}
	}

	return product_categories, count
}

fn model_product_category_delete(mut tx firebird.Transaction, product_category_id_bin []u8) ! {
	tx.execute('UPDATE product_category SET deleted_at = CURRENT_TIMESTAMP WHERE id = ?',
		product_category_id_bin)!
}

// TODO get tranlsations

fn model_product_category_product_update(mut tx firebird.Transaction, product_id_bin []u8, category_ids_bin [][]u8) ! {
	mut src := []string{len: category_ids_bin.len}
	mut params := []firebird.Value{len: category_ids_bin.len * 2 + 1, init: firebird.Value(firebird.Null{})}
	for i := 0; i < category_ids_bin.len; i++ {
		src[i] = 'SELECT ? AS product_id, ? AS product_category_id FROM RDB\$DATABASE'
		params[i * 2] = product_id_bin
		params[i * 2 + 1] = category_ids_bin[i]
	}
	params[category_ids_bin.len * 2] = product_id_bin

	tx.execute('MERGE INTO product_category_product t
			USING (${get_merge_source(src)}) s (product_id, product_category_id)
			ON (t.product_id = s.product_id AND t.product_category_id = s.product_category_id)
			WHEN NOT MATCHED THEN
				INSERT (product_id, product_category_id)
				VALUES (s.product_id, s.product_category_id)
			WHEN NOT MATCHED BY SOURCE AND t.product_id = ? THEN DELETE',
		...params)!
}
