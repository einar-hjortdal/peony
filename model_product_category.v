module peony

import arrays
import einar_hjortdal.firebird

struct ProductCategoryTranslation {
	product_category_id     string
	product_category_id_bin []u8
	locale_id               string
	locale_id_bin           []u8
	name                    string
	description             firebird.NullString
}

fn model_product_category_translations_merge(mut tx firebird.Transaction, product_category_id_bin []u8, ph []ProductCategoryTranslationRequestHygienised) ! {
	mut src := []string{len: ph.len}
	mut params := []firebird.Value{len: ph.len * 4 + 1, init: firebird.Value(firebird.Null{})}
	for i := 0; i < ph.len; i++ {
		src[i] = 'SELECT
			CAST(? AS BINARY(16)) AS product_category_id,
			CAST(? AS BINARY(16)) AS locale_id,
			CAST(? AS VARCHAR(63)) AS name,
			CAST(? as BLOB SUB_TYPE TEXT) AS description
			FROM RDB\$DATABASE'
		params[i * 4] = product_category_id_bin
		params[i * 4 + 1] = ph[i].locale_id_bin
		params[i * 4 + 2] = ph[i].name

		if description := ph[i].description {
			params[i * 4 + 3] = description
		} else {
			params[i * 4 + 3] = firebird.Null{}
		}
	}
	params[ph.len * 4] = product_category_id_bin

	tx.execute('MERGE INTO product_category_translations t
		USING (${get_merge_source(src)}) s
		ON (t.product_category_id = s.product_category_id AND t.locale_id = s.locale_id)
		WHEN MATCHED THEN
			UPDATE SET name = s.name
		WHEN NOT MATCHED THEN
			INSERT (product_category_id, locale_id, name)
			VALUES (s.product_category_id, s.locale_id, s.name)
		WHEN NOT MATCHED BY SOURCE AND t.product_category_id = ? THEN
			DELETE',
		...params)!
}

fn model_product_category_translations_get(mut tx firebird.Transaction, product_category_ids_bin [][]u8) ![]ProductCategoryTranslation {
	data := tx.execute('SELECT product_category_id, locale_id, name, description
		FROM product_category_translations
		WHERE product_category_id IN (${get_placeholders(product_category_ids_bin)})',
		...workaround_24757(product_category_ids_bin))!

	rows := data.rows()
	mut product_category_translations := []ProductCategoryTranslation{len: rows.len}
	for i := 0; i < rows.len; i++ {
		translation := rows[i].values()

		product_category_id_bin, _ := translation[0].get_array_u8()!
		locale_id_bin, _ := translation[1].get_array_u8()!
		name, _ := translation[2].get_string()!
		description := translation[3].get_null_string()!

		product_category_id := id_bin_to_string(product_category_id_bin)!
		locale_id := id_bin_to_string(locale_id_bin)!

		product_category_translations[i] = ProductCategoryTranslation{
			product_category_id:     product_category_id
			product_category_id_bin: product_category_id_bin
			locale_id:               locale_id
			locale_id_bin:           locale_id_bin
			name:                    name
			description:             description
		}
	}
	return product_category_translations
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
	category_rank          i32
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

	if category_rank := ph.category_rank {
		columns = arrays.concat(columns, 'category_rank')
		params = arrays.concat(params, category_rank)
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

	if category_rank := ph.category_rank {
		columns = arrays.concat(columns, 'category_rank')
		params = arrays.concat(params, category_rank)
	}

	tx.execute('UPDATE product_category SET ${get_set_columns_with_updated_at(columns)} WHERE id = ?',
		...params)!
}

fn model_product_category_retrieve_cte(ph ProductCategoryParamsRetrieveHygienised) (string, []firebird.Value) {
	if ph.parent_category_ids.is_set {
		return 'WITH RECURSIVE descendants (id) AS (
			SELECT id FROM product_category
				WHERE parent_category_id IN (${get_placeholders(ph.parent_category_id_bins)})
			UNION ALL
			SELECT pc.id
				FROM product_category pc JOIN descendants d
				ON pc.parent_category_id = d.id
			)', workaround_24757(ph.parent_category_id_bins)
	}
	return '', []firebird.Value{}
}

fn model_product_category_retrieve_conditions(ph ProductCategoryParamsRetrieveHygienised) (string, []firebird.Value) {
	mut conditions := []string{}
	mut params := []firebird.Value{}

	if ph.ids.is_set {
		conditions = arrays.concat(conditions, 'id IN (${get_placeholders(ph.ids_bin)})')
		params = arrays.concat(params, ...workaround_24757(ph.ids_bin))
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

	if ph.product_ids.is_set {
		conditions = arrays.concat(conditions, 'EXISTS (
		SELECT 1 FROM product_category_product pcp
		WHERE pcp.product_category_id = product_category.id
			AND pcp.product_id IN (${get_placeholders(ph.product_ids_bin)})
		)')
		params = arrays.concat(params, ...workaround_24757(ph.product_ids_bin))
	}

	if !ph.with_deleted.is_set || ph.with_deleted.v {
		conditions = arrays.concat(conditions, 'deleted_at IS NULL')
	}

	return get_where_conditions(conditions), params
}

fn model_product_category_retrieve_count(mut tx firebird.Transaction, ph ProductCategoryParamsRetrieveHygienised) !i64 {
	cte, cte_params := model_product_category_retrieve_cte(ph)
	conditions, conditions_params := model_product_category_retrieve_conditions(ph)
	data := tx.execute(appendln(cte, '${cte}SELECT COUNT(*) FROM product_category ${conditions}'),
		...arrays.append(cte_params, conditions_params))!
	rows := data.rows()
	values := rows[0].values() // should always return one row
	count, _ := values[0].get_i64()! // should always return one column
	return count
}

fn model_product_category_retrieve(mut tx firebird.Transaction, ph ProductCategoryParamsRetrieveHygienised) ![]ProductCategory {
	cte, cte_params := model_product_category_retrieve_cte(ph)
	conditions, conditions_params := model_product_category_retrieve_conditions(ph)

	mut params := arrays.append(cte_params, conditions_params)
	mut sorting := 'ORDER BY created_at ${get_sorting_order(ph.order)},
		category_rank ${get_sorting_order(ph.order)}'

	if ph.offset.is_set {
		sorting = appendln(sorting, 'OFFSET ? ROWS')
		params = arrays.concat(params, ph.offset.v)
	}

	if ph.fetch.is_set {
		sorting = appendln(sorting, 'FETCH NEXT ? ROWS ONLY')
		params = arrays.concat(params, ph.fetch.v)
	}

	data := tx.execute('${cte} SELECT
		id,
		created_at,
		updated_at,
		deleted_at,
		handle,
		is_active,
		is_internal,
		parent_category_id,
		category_rank,
		metadata
		FROM product_category ${conditions} ${sorting}',
		...params)!

	rows := data.rows()

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
		category_rank, _ := v[8].get_i32()!
		metadata := v[9].get_null_string()!

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
			category_rank:          category_rank
			parent_category_id:     parent_category_id
			parent_category_id_bin: parent_category_id_bin
			metadata:               metadata
		}
	}

	return product_categories
}

fn model_product_category_delete(mut tx firebird.Transaction, product_category_id_bin []u8) ! {
	tx.execute('UPDATE product_category SET deleted_at = CURRENT_TIMESTAMP WHERE id = ?',
		product_category_id_bin)!
}

// TODO get tranlsations

struct ProductCategoryProduct {
	product_category_id     string
	product_category_id_bin []u8
	product_id              string
	product_id_bin          []u8
}

struct ProductCategoryProductRetrieveParams {
	product_category_ids_bin [][]u8
	product_ids_bin          [][]u8
}

fn model_product_category_product_retrieve(mut tx firebird.Transaction,
	p ProductCategoryProductRetrieveParams) ![]ProductCategoryProduct {
	if p.product_category_ids_bin.len == 0 && p.product_ids_bin.len == 0 {
		return []ProductCategoryProduct{}
	}

	if p.product_category_ids_bin.len > 0 && p.product_ids_bin.len > 0 {
		return new_internal_error('received both product_category_ids_bin abd product_ids_bin',
			'model_product_category_product_retrieve')
	}

	mut condition := ''
	mut params := []firebird.Value{}
	if p.product_category_ids_bin.len > 0 {
		condition = 'product_category_id'
		params = workaround_24757(p.product_category_ids_bin)
	}

	if p.product_ids_bin.len > 0 {
		condition = 'product_id'
		params = workaround_24757(p.product_ids_bin)
	}

	data := tx.execute('SELECT product_category_id, product_id
		FROM product_category_product WHERE ${condition} IN (${get_placeholders(params)})',
		...params)!

	rows := data.rows()

	mut product_category_products := []ProductCategoryProduct{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()
		product_category_id_bin, _ := v[0].get_array_u8()!
		product_id_bin, _ := v[1].get_array_u8()!

		product_category_id := id_bin_to_string(product_category_id_bin)!
		product_id := id_bin_to_string(product_id_bin)!

		product_category_products[i] = ProductCategoryProduct{
			product_category_id_bin: product_category_id_bin
			product_category_id:     product_category_id
			product_id_bin:          product_id_bin
			product_id:              product_id
		}
	}
	return product_category_products
}

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
