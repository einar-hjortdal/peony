module peony

import arrays
import einar_hjortdal.firebird

struct ProductCategoryTranslation {
	product_category_id     string
	product_category_id_bin []u8
	locale_id               string
	locale_id_bin           []u8
	name                    firebird.NullString
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

		if name := ph[i].name {
			params[i * 4 + 2] = name
		} else {
			params[i * 4 + 2] = firebird.Null{}
		}

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
			UPDATE SET 
				name = s.name,
				description = s.description
		WHEN NOT MATCHED THEN
			INSERT (product_category_id, locale_id, name)
			VALUES (s.product_category_id, s.locale_id, s.name)
		WHEN NOT MATCHED BY SOURCE AND t.product_category_id = ? THEN
			DELETE',
		...params)!
}

fn model_category_translations_get(mut tx firebird.Transaction, product_category_ids_bin [][]u8) ![]ProductCategoryTranslation {
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
		name := translation[2].get_null_string()!
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
	parent_category_id_bin []u8
	metadata               firebird.NullString
	name                   firebird.NullString
	description            firebird.NullString
	seo_title              firebird.NullString
	seo_description        firebird.NullString
mut:
	translations     []ProductCategoryTranslation
	seo_translations []ProductCategorySEOTranslation
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

	params = arrays.concat(params, product_category_id_bin)

	tx.execute('UPDATE product_category SET ${get_set_columns_with_updated_at(columns)} WHERE id = ?',
		...params)!
}

struct ProductCategoryRetrieveParams {
	filter_by_id                  bool
	ids_bin                       [][]u8
	filter_by_handle              bool
	handles                       []string
	filter_by_is_active           bool
	is_active                     bool
	filter_by_is_internal         bool
	is_internal                   bool
	filter_by_product_ids         bool
	product_ids_bin               [][]u8
	filter_by_parent_category_ids bool
	parent_category_ids_bin       [][]u8
	include_parents               bool
	include_deleted               bool
	locale_id_bin                 []u8
	use_offset                    bool
	offset                        i32
	use_fetch                     bool
	fetch                         i32
	use_order_direction           bool
	order_direction               string
}

fn model_product_category_retrieve_conditions(p ProductCategoryRetrieveParams) (string, []firebird.Value) {
	mut conditions := []string{}
	mut params := []firebird.Value{}

	if p.filter_by_id {
		conditions = arrays.concat(conditions, 'pc.id IN (${get_placeholders(p.ids_bin)})')
		params = arrays.concat(params, ...workaround_24757(p.ids_bin))
	}

	if p.filter_by_handle {
		conditions = arrays.concat(conditions, 'pc.handle IN (${get_placeholders(p.handles)})')
		params = arrays.concat(params, ...p.handles)
	}

	if p.filter_by_is_active {
		conditions = arrays.concat(conditions, 'pc.is_active = ?')
		params = arrays.concat(params, p.is_active)
	}

	if p.filter_by_is_internal {
		conditions = arrays.concat(conditions, 'pc.is_internal = ?')
		params = arrays.concat(params, p.is_internal)
	}

	if p.filter_by_product_ids {
		conditions = arrays.concat(conditions, 'EXISTS (
		SELECT 1 FROM product_category_product pcp
		WHERE pcp.product_category_id = pc.id
			AND pcp.product_id IN (${get_placeholders(p.product_ids_bin)})
		)')
		params = arrays.concat(params, ...workaround_24757(p.product_ids_bin))
	}

	if !p.include_deleted {
		conditions = arrays.concat(conditions, 'pc.deleted_at IS NULL')
	}

	return get_where_conditions(conditions), params
}

fn model_product_category_retrieve_count(mut tx firebird.Transaction, p ProductCategoryRetrieveParams) !i64 {
	conditions, params := model_product_category_retrieve_conditions(p)
	data := tx.execute('SELECT COUNT(*) FROM product_category pc ${conditions}', ...params)!
	rows := data.rows()
	values := rows[0].values() // should always return one row
	count, _ := values[0].get_i64()! // should always return one column
	return count
}

fn model_product_category_retrieve(mut tx firebird.Transaction, p ProductCategoryRetrieveParams) ![]ProductCategory {
	mut params := []firebird.Value{}

	// 2 for translations, 2 for seo
	if p.locale_id_bin.len > 0 {
		params = arrays.concat(params, p.locale_id_bin, p.locale_id_bin, p.locale_id_bin,
			p.locale_id_bin)
	} else {
		params = arrays.concat(params, firebird.Null{}, firebird.Null{}, firebird.Null{},
			firebird.Null{})
	}

	conditions, conditions_params := model_product_category_retrieve_conditions(p)
	params = arrays.append(params, conditions_params)

	mut order_direction := order_direction_default
	if p.use_order_direction {
		order_direction = p.order_direction
	}

	mut sorting := 'ORDER BY pc.created_at ${order_direction}, pc.category_rank ${order_direction}'

	if p.use_offset {
		sorting = appendln(sorting, 'OFFSET ? ROWS')
		params = arrays.concat(params, p.offset)
	}

	if p.use_fetch {
		sorting = appendln(sorting, 'FETCH NEXT ? ROWS ONLY')
		params = arrays.concat(params, p.fetch)
	}

	data := tx.execute('SELECT
		pc.id,
		pc.created_at,
		pc.updated_at,
		pc.deleted_at,
		pc.handle,
		pc.is_active,
		pc.is_internal,
		pc.parent_category_id,
		pc.category_rank,
		pc.metadata,
		COALESCE(pct_requested.name, pct_default.name) AS name,
		COALESCE(pct_requested.description, pct_default.description) AS description,
		COALESCE(seo_requested.title, seo_default.title) AS seo_title,
		COALESCE(seo_requested.description, seo_default.description) AS seo_description
		FROM product_category pc
		LEFT JOIN product_category_translations pct_default
			ON pct_default.product_category_id = pc.id
			AND pct_default.locale_id = (
				SELECT default_locale_id FROM store
			)
		LEFT JOIN product_category_translations pct_requested
			ON CAST(? AS BINARY(16)) IS NOT NULL
			AND pct_requested.product_category_id = pc.id
			AND pct_requested.locale_id = ?
		LEFT JOIN seo_translations seo_default
			ON seo_default.product_category_id = pc.id
			AND seo_default.locale_id = (
				SELECT default_locale_id FROM store
			)
		LEFT JOIN seo_translations seo_requested
			ON CAST(? AS BINARY(16)) IS NOT NULL
			AND seo_requested.product_category_id = pc.id
			AND seo_requested.locale_id = ?
		${conditions} ${sorting}',
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
		parent_category_id_bin, _ := v[7].get_array_u8()!
		category_rank, _ := v[8].get_i32()!
		metadata := v[9].get_null_string()!
		name := v[10].get_null_string()!
		description := v[11].get_null_string()!

		id := id_bin_to_string(id_bin)!

		mut parent_category_id := ''
		if parent_category_id_bin.len > 0 {
			parent_category_id = id_bin_to_string(parent_category_id_bin)!
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
			name:                   name
			description:            description
		}
	}

	return product_categories
}

fn model_product_category_delete(mut tx firebird.Transaction, product_category_id_bin []u8) ! {
	tx.execute('UPDATE product_category SET deleted_at = CURRENT_TIMESTAMP WHERE id = ?',
		product_category_id_bin)!
}

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
		return new_internal_error('received both product_category_ids_bin and product_ids_bin',
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
		src[i] = 'SELECT 
			CAST(? AS BINARY(16)) AS product_id,
			CAST(? AS BINARY(16)) AS product_category_id
			FROM RDB\$DATABASE'
		params[i * 2] = product_id_bin
		params[i * 2 + 1] = category_ids_bin[i]
	}
	params[category_ids_bin.len * 2] = product_id_bin

	tx.execute('MERGE INTO product_category_product t
			USING (${get_merge_source(src)}) s
			ON (t.product_id = s.product_id AND t.product_category_id = s.product_category_id)
			WHEN NOT MATCHED THEN
				INSERT (product_id, product_category_id)
				VALUES (s.product_id, s.product_category_id)
			WHEN NOT MATCHED BY SOURCE AND t.product_id = ? THEN 
				DELETE',
		...params)!
}
