module peony

import arrays
import einar_hjortdal.firebird

struct CategoryTranslation {
	category_id     string
	category_id_bin []u8
	locale_id       string
	locale_id_bin   []u8
	name            firebird.NullString
	description     firebird.NullString
}

fn model_category_translations_delete(mut tx firebird.Transaction, category_id_bin []u8) ! {
	tx.execute('DELETE FROM category_translations WHERE category_id = ?', category_id_bin)!
}

fn model_category_translations_update(mut tx firebird.Transaction, category_id_bin []u8, ph []CategoryTranslationRequestHygienised) ! {
	mut src := []string{len: ph.len}
	mut params := []firebird.Value{len: ph.len * 4, init: firebird.Null{}}
	for i := 0; i < ph.len; i++ {
		src[i] = 'SELECT
			CAST(? AS BINARY(16)) AS category_id,
			CAST(? AS BINARY(16)) AS locale_id,
			CAST(? AS VARCHAR(63)) AS name,
			CAST(? AS BLOB SUB_TYPE TEXT) AS description
			FROM RDB\$DATABASE'

		params[i * 4] = category_id_bin
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

	tx.execute('INSERT INTO category_translations (category_id, locale_id, name, description)
		${get_merge_source(src)}',
		...params)!
}

fn model_category_translations_get(mut tx firebird.Transaction, category_ids_bin [][]u8) ![]CategoryTranslation {
	data := tx.execute('SELECT category_id, locale_id, name, description
		FROM category_translations
		WHERE category_id IN (${get_placeholders(category_ids_bin)})',
		...workaround_24757(category_ids_bin))!

	rows := data.rows()
	mut category_translations := []CategoryTranslation{len: rows.len}
	for i := 0; i < rows.len; i++ {
		translation := rows[i].values()

		category_id_bin, _ := translation[0].get_array_u8()!
		locale_id_bin, _ := translation[1].get_array_u8()!
		name := translation[2].get_null_string()!
		description := translation[3].get_null_string()!

		category_id := id_bin_to_string(category_id_bin)!
		locale_id := id_bin_to_string(locale_id_bin)!

		category_translations[i] = CategoryTranslation{
			category_id:     category_id
			category_id_bin: category_id_bin
			locale_id:       locale_id
			locale_id_bin:   locale_id_bin
			name:            name
			description:     description
		}
	}
	return category_translations
}

struct Category {
	id                     string
	id_bin                 []u8
	created_at             firebird.DateTime
	updated_at             firebird.DateTime
	deleted_at             firebird.NullDateTime
	name                   string
	description            firebird.NullString
	handle                 string
	is_active              bool
	is_internal            bool
	parent_category_id     string
	parent_category_id_bin []u8
	metadata               firebird.NullString
mut:
	seo          CategorySEO
	translations []CategoryTranslation
}

fn model_category_create(mut tx firebird.Transaction, id string, id_bin []u8, ph CategoryCreateRequestHygienised) ! {
	mut columns := ['id', 'name', 'handle']
	mut params := [firebird.Value(id_bin), ph.name]

	// TODO just use handle (trust it is unique and safe in the params)
	if handle := ph.handle {
		params = arrays.concat(params, handle)
	} else {
		params = arrays.concat(params, id)
	}

	if description := ph.description {
		columns = arrays.concat(columns, 'description')
		params = arrays.concat(params, description)
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

	tx.execute('INSERT INTO category (${get_columns(columns)}) 
		VALUES (${get_placeholders(params)})',
		...params)!
}

fn model_category_update(mut tx firebird.Transaction, category_id_bin []u8, ph CategoryUpdateRequestHygienised) ! {
	mut columns := []string{}
	mut params := []firebird.Value{}

	if name := ph.name {
		columns = arrays.concat(columns, 'name')
		params = arrays.concat(params, name)
	}

	if description := ph.description {
		columns = arrays.concat(columns, 'description')
		params = arrays.concat(params, description)
	}

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

	params = arrays.concat(params, category_id_bin)

	tx.execute('UPDATE category SET ${get_set_columns_with_updated_at(columns)} WHERE id = ?',
		...params)!
}

struct CategoryRetrieveParams {
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
	fetch                         i32
	use_order_direction           bool
	order_direction               string
}

fn model_category_retrieve_conditions(p CategoryRetrieveParams) (string, []firebird.Value) {
	mut conditions := []string{}
	mut params := []firebird.Value{}

	if p.filter_by_id {
		conditions = arrays.concat(conditions, 'c.id IN (${get_placeholders(p.ids_bin)})')
		params = arrays.concat(params, ...workaround_24757(p.ids_bin))
	}

	if p.filter_by_handle {
		conditions = arrays.concat(conditions, 'c.handle IN (${get_placeholders(p.handles)})')
		params = arrays.concat(params, ...p.handles)
	}

	if p.filter_by_is_active {
		conditions = arrays.concat(conditions, 'c.is_active = ?')
		params = arrays.concat(params, p.is_active)
	}

	if p.filter_by_is_internal {
		conditions = arrays.concat(conditions, 'c.is_internal = ?')
		params = arrays.concat(params, p.is_internal)
	}

	if p.filter_by_product_ids {
		conditions = arrays.concat(conditions, 'EXISTS (
		SELECT 1 FROM category_product cp
		WHERE cp.category_id = c.id
			AND cp.product_id IN (${get_placeholders(p.product_ids_bin)})
		)')
		params = arrays.concat(params, ...workaround_24757(p.product_ids_bin))
	}

	if !p.include_deleted {
		conditions = arrays.concat(conditions, 'c.deleted_at IS NULL')
	}

	return get_where_conditions(conditions), params
}

fn model_category_retrieve_count(mut tx firebird.Transaction, p CategoryRetrieveParams) !i64 {
	conditions, params := model_category_retrieve_conditions(p)
	data := tx.execute('SELECT COUNT(*) FROM category c ${conditions}', ...params)!
	rows := data.rows()
	values := rows[0].values() // should always return one row
	count, _ := values[0].get_i64()! // should always return one column
	return count
}

fn model_category_retrieve(mut tx firebird.Transaction, p CategoryRetrieveParams) ![]Category {
	conditions, mut params := model_category_retrieve_conditions(p)

	mut order_direction := order_direction_default
	if p.use_order_direction {
		order_direction = p.order_direction
	}

	mut sorting := 'ORDER BY c.created_at ${order_direction}'

	if p.use_offset {
		sorting = appendln(sorting, 'OFFSET ? ROWS')
		params = arrays.concat(params, p.offset)
	}

	sorting = appendln(sorting, 'FETCH NEXT ? ROWS ONLY')
	params = arrays.concat(params, p.fetch)

	data := tx.execute('SELECT
		c.id,
		c.created_at,
		c.updated_at,
		c.deleted_at,
		c.name,
		c.description,
		c.handle,
		c.is_active,
		c.is_internal,
		c.parent_category_id,
		c.metadata
		FROM category c
		${conditions}
		${sorting}',
		...params)!

	rows := data.rows()

	mut categories := []Category{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()

		id_bin, _ := v[0].get_array_u8()!
		created_at, _ := v[1].get_date_time()!
		updated_at, _ := v[2].get_date_time()!
		deleted_at := v[3].get_null_date_time()!
		name, _ := v[4].get_string()!
		description := v[5].get_null_string()!
		handle, _ := v[6].get_string()!
		is_active, _ := v[7].get_bool()!
		is_internal, _ := v[8].get_bool()!
		parent_category_id_bin, _ := v[9].get_array_u8()!
		metadata := v[10].get_null_string()!

		id := id_bin_to_string(id_bin)!

		mut parent_category_id := ''
		if parent_category_id_bin.len > 0 {
			parent_category_id = id_bin_to_string(parent_category_id_bin)!
		}

		categories[i] = Category{
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
			name:                   name
			description:            description
		}
	}

	return categories
}

fn model_category_delete(mut tx firebird.Transaction, category_id_bin []u8) ! {
	tx.execute('UPDATE category SET deleted_at = CURRENT_TIMESTAMP WHERE id = ?', category_id_bin)!
}

struct CategoryProduct {
	category_id     string
	category_id_bin []u8
	product_id      string
	product_id_bin  []u8
}

struct CategoryProductRetrieveParams {
	category_ids_bin [][]u8
	product_ids_bin  [][]u8
}

fn model_category_product_retrieve(mut tx firebird.Transaction,
	p CategoryProductRetrieveParams) ![]CategoryProduct {
	if p.category_ids_bin.len == 0 && p.product_ids_bin.len == 0 {
		return []CategoryProduct{}
	}

	if p.category_ids_bin.len > 0 && p.product_ids_bin.len > 0 {
		return new_error_internal('received both category_ids_bin and product_ids_bin',
			'model_category_product_retrieve')
	}

	mut condition := ''
	mut params := []firebird.Value{}
	if p.category_ids_bin.len > 0 {
		condition = 'category_id'
		params = workaround_24757(p.category_ids_bin)
	}

	if p.product_ids_bin.len > 0 {
		condition = 'product_id'
		params = workaround_24757(p.product_ids_bin)
	}

	data := tx.execute('SELECT category_id, product_id
		FROM category_product WHERE ${condition} IN (${get_placeholders(params)})',
		...params)!

	rows := data.rows()

	mut category_products := []CategoryProduct{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()
		category_id_bin, _ := v[0].get_array_u8()!
		product_id_bin, _ := v[1].get_array_u8()!

		category_id := id_bin_to_string(category_id_bin)!
		product_id := id_bin_to_string(product_id_bin)!

		category_products[i] = CategoryProduct{
			category_id_bin: category_id_bin
			category_id:     category_id
			product_id_bin:  product_id_bin
			product_id:      product_id
		}
	}
	return category_products
}

fn model_category_product_update(mut tx firebird.Transaction, product_id_bin []u8, category_ids_bin [][]u8) ! {
	mut src := []string{len: category_ids_bin.len}
	mut params := []firebird.Value{len: category_ids_bin.len * 2 + 1, init: firebird.Null{}}
	for i := 0; i < category_ids_bin.len; i++ {
		src[i] = 'SELECT 
			CAST(? AS BINARY(16)) AS product_id,
			CAST(? AS BINARY(16)) AS category_id
			FROM RDB\$DATABASE'
		params[i * 2] = product_id_bin
		params[i * 2 + 1] = category_ids_bin[i]
	}
	params[category_ids_bin.len * 2] = product_id_bin

	tx.execute('MERGE INTO category_product t
			USING (${get_merge_source(src)}) s
			ON (t.product_id = s.product_id AND t.category_id = s.category_id)
			WHEN NOT MATCHED THEN
				INSERT (product_id, category_id)
				VALUES (s.product_id, s.category_id)
			WHEN NOT MATCHED BY SOURCE AND t.product_id = ? THEN 
				DELETE',
		...params)!
}
