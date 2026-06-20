module record

import arrays
import einar_hjortdal.firebird

pub struct CategoryTranslation {
pub:
	category_id ID
	locale_id   ID
	name        ?string
	description ?string
}

pub fn (ct CategoryTranslation) locale_id() ID {
	return ct.locale_id
}

pub fn category_translations_delete(mut tx firebird.ClientTransaction, category_id ID) ! {
	tx.execute('DELETE FROM category_translations WHERE category_id = ?', category_id.bytes())!
}

pub struct CategoryTranslationCreateParams {
pub:
	locale_id   ID
	name        ?string
	description ?string
}

pub fn (p CategoryTranslationCreateParams) locale_id() ID {
	return p.locale_id
}

pub fn category_translations_create(mut tx firebird.ClientTransaction, category_id ID, p []CategoryTranslationCreateParams) ! {
	mut src := []string{len: p.len}
	mut params := []firebird.Value{len: p.len * 4, init: firebird.Null{}}
	for i := 0; i < p.len; i++ {
		src[i] = 'SELECT
			CAST(? AS BINARY(16)) AS category_id,
			CAST(? AS BINARY(16)) AS locale_id,
			CAST(? AS VARCHAR(63)) AS name,
			CAST(? AS BLOB SUB_TYPE TEXT) AS description
			FROM RDB\$DATABASE'

		params[i * 4] = category_id.bytes()
		params[i * 4 + 1] = p[i].locale_id.bytes()

		if name := p[i].name {
			params[i * 4 + 2] = name
		} else {
			params[i * 4 + 2] = firebird.Null{}
		}

		if description := p[i].description {
			params[i * 4 + 3] = description
		} else {
			params[i * 4 + 3] = firebird.Null{}
		}
	}

	tx.execute('INSERT INTO category_translations (category_id, locale_id, name, description)
		${get_merge_source(src)}',
		...params)!
}

pub fn category_translations_get(mut tx firebird.ClientTransaction, category_ids []ID) ![]CategoryTranslation {
	data := tx.execute('SELECT category_id, locale_id, name, description
		FROM category_translations
		WHERE category_id IN (${get_placeholders(category_ids)})',
		...ids_bytes(category_ids))!

	rows := data.rows()
	mut category_translations := []CategoryTranslation{len: rows.len}
	for i := 0; i < rows.len; i++ {
		translation := rows[i].values()

		category_id_bin, _ := translation[0].get_array_u8()!
		locale_id_bin, _ := translation[1].get_array_u8()!
		name := translation[2].get_null_string()!
		description := translation[3].get_null_string()!

		category_id := id_from_bytes(category_id_bin)!
		locale_id := id_from_bytes(locale_id_bin)!

		category_translations[i] = CategoryTranslation{
			category_id: category_id
			locale_id:   locale_id
			name:        name.none_value()
			description: description.none_value()
		}
	}
	return category_translations
}

pub struct Category {
pub:
	id                 ID
	created_at         firebird.DateTime
	updated_at         firebird.DateTime
	deleted_at         ?firebird.DateTime
	name               string
	description        ?string
	handle             string
	is_active          bool
	is_internal        bool
	parent_category_id ?ID
	metadata           ?string
pub mut:
	seo          CategorySEO
	translations []CategoryTranslation
}

pub fn (c Category) id() ID {
	return c.id
}

pub struct CategoryCreateParams {
pub:
	id                 ID
	name               string
	handle             string
	description        ?string
	is_active          bool
	is_internal        bool
	metadata           ?string
	parent_category_id ?ID
}

pub fn category_create(mut tx firebird.ClientTransaction, p CategoryCreateParams) ! {
	mut columns := ['id', 'name', 'handle', 'is_active', 'is_internal']
	mut params := [firebird.Value(p.id.bytes()), p.name, p.handle, p.is_active, p.is_internal]

	if description := p.description {
		columns = arrays.concat(columns, 'description')
		params = arrays.concat(params, description)
	}

	if metadata := p.metadata {
		columns = arrays.concat(columns, 'metadata')
		params = arrays.concat(params, metadata)
	}

	if parent_category_id := p.parent_category_id {
		columns = arrays.concat(columns, 'parent_category_id')
		params = arrays.concat(params, parent_category_id.bytes())
	}

	tx.execute('INSERT INTO category (${get_columns(columns)}) 
		VALUES (${get_placeholders(params)})',
		...params)!
}

pub struct CategoryUpdateParams {
pub:
	id                 ID
	name               ?string
	description        ?string
	handle             ?string
	is_active          ?bool
	is_internal        ?bool
	metadata           ?string
	parent_category_id ?ID
}

pub fn category_update(mut tx firebird.ClientTransaction, p CategoryUpdateParams) ! {
	mut columns := []string{}
	mut params := []firebird.Value{}

	if name := p.name {
		columns = arrays.concat(columns, 'name')
		params = arrays.concat(params, name)
	}

	if description := p.description {
		columns = arrays.concat(columns, 'description')
		params = arrays.concat(params, description)
	}

	if handle := p.handle {
		columns = arrays.concat(columns, 'handle')
		params = arrays.concat(params, handle)
	}

	if is_active := p.is_active {
		columns = arrays.concat(columns, 'is_active')
		params = arrays.concat(params, is_active)
	}

	if is_internal := p.is_internal {
		columns = arrays.concat(columns, 'is_internal')
		params = arrays.concat(params, is_internal)
	}

	if metadata := p.metadata {
		columns = arrays.concat(columns, 'metadata')
		params = arrays.concat(params, metadata)
	}

	if parent_category_id := p.parent_category_id {
		columns = arrays.concat(columns, 'parent_category_id')
		params = arrays.concat(params, parent_category_id.bytes())
	}

	params = arrays.concat(params, p.id.bytes())

	tx.execute('UPDATE category SET ${get_set_columns_with_updated_at(columns)} WHERE id = ?',
		...params)!
}

pub struct CategoryRetrieveParams {
pub:
	ids                ?[]ID
	handle             ?string
	is_active          ?bool
	is_internal        ?bool
	product_ids        ?[]ID
	parent_category_id ?ID
	with_deleted       bool
	offset             i32
	fetch              i32
	order              string
}

pub fn category_retrieve_conditions(p CategoryRetrieveParams) (string, []firebird.Value) {
	mut conditions := []string{}
	mut params := []firebird.Value{}

	if ids := p.ids {
		conditions = arrays.concat(conditions, 'c.id IN (${get_placeholders(ids)})')
		params = arrays.concat(params, ...ids_bytes(ids))
	}

	if handle := p.handle {
		conditions = arrays.concat(conditions, 'c.handle = ?')
		params = arrays.concat(params, handle)
	}

	if is_active := p.is_active {
		conditions = arrays.concat(conditions, 'c.is_active = ?')
		params = arrays.concat(params, is_active)
	}

	if is_internal := p.is_internal {
		conditions = arrays.concat(conditions, 'c.is_internal = ?')
		params = arrays.concat(params, is_internal)
	}

	if product_ids := p.product_ids {
		conditions = arrays.concat(conditions, 'EXISTS (
			SELECT 1 FROM category_product cp
			WHERE cp.category_id = c.id
				AND cp.product_id IN (${get_placeholders(product_ids)})
			)')
		params = arrays.concat(params, ...ids_bytes(product_ids))
	}

	if !p.with_deleted {
		conditions = arrays.concat(conditions, 'c.deleted_at is NULL')
	}

	return get_where_conditions(conditions), params
}

pub fn category_retrieve_count(mut tx firebird.ClientTransaction, p CategoryRetrieveParams) !i64 {
	conditions, params := category_retrieve_conditions(p)
	data := tx.execute('SELECT COUNT(*) FROM category c ${conditions}', ...params)!
	rows := data.rows()
	values := rows[0].values() // should always return one row
	count, _ := values[0].get_i64()! // should always return one column
	return count
}

pub fn category_retrieve(mut tx firebird.ClientTransaction, p CategoryRetrieveParams) ![]Category {
	conditions, mut params := category_retrieve_conditions(p)

	mut sorting := 'ORDER BY c.created_at ${p.order}
		OFFSET ? ROWS
		FETCH NEXT ? ROWS ONLY'
	params = arrays.concat(params, p.offset, p.fetch)

	query := 'SELECT
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
		${sorting}'

	data := tx.execute(query, ...params)!
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
		parent_category_id_bin := v[9].get_null_array_u8()!
		metadata := v[10].get_null_string()!

		id := id_from_bytes(id_bin)!

		mut parent_category_id := ?ID(none)
		if !parent_category_id_bin.is_null() {
			parent_category_id = id_from_bytes(parent_category_id_bin.value())!
		}

		categories[i] = Category{
			id:                 id
			created_at:         created_at
			updated_at:         updated_at
			deleted_at:         deleted_at.none_value()
			handle:             handle
			is_active:          is_active
			is_internal:        is_internal
			parent_category_id: parent_category_id
			metadata:           metadata.none_value()
			name:               name
			description:        description.none_value()
		}
	}

	return categories
}

pub fn category_delete(mut tx firebird.ClientTransaction, category_id ID) ! {
	tx.execute('UPDATE category SET deleted_at = CURRENT_TIMESTAMP WHERE id = ?',
		category_id.bytes())!
}

pub struct CategoryProduct {
pub:
	category_id ID
	product_id  ID
}

pub struct CategoryProductRetrieveParams {
pub:
	category_ids ?[]ID
	product_ids  ?[]ID
}

pub fn category_product_retrieve(mut tx firebird.ClientTransaction,
	p CategoryProductRetrieveParams) ![]CategoryProduct {
	if p.category_ids == none && p.product_ids == none {
		return []CategoryProduct{}
	}

	if p.category_ids != none && p.product_ids != none {
		return error('received both category_ids_bin and product_ids_bin')
	}

	mut condition := ''
	mut params := []firebird.Value{}
	if category_ids := p.category_ids {
		condition = 'category_id'
		params = ids_values(category_ids)
	}

	if product_ids := p.product_ids {
		condition = 'product_id'
		params = ids_values(product_ids)
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

		category_id := id_from_bytes(category_id_bin)!
		product_id := id_from_bytes(product_id_bin)!

		category_products[i] = CategoryProduct{
			category_id: category_id
			product_id:  product_id
		}
	}
	return category_products
}

pub fn category_product_update(mut tx firebird.ClientTransaction, product_id ID, category_ids []ID) ! {
	mut src := []string{len: category_ids.len}
	mut params := []firebird.Value{len: category_ids.len * 2 + 1, init: firebird.Null{}}
	for i := 0; i < category_ids.len; i++ {
		src[i] = 'SELECT 
			CAST(? AS BINARY(16)) AS product_id,
			CAST(? AS BINARY(16)) AS category_id
			FROM RDB\$DATABASE'
		params[i * 2] = product_id.bytes()
		params[i * 2 + 1] = category_ids[i].bytes()
	}
	params[category_ids.len * 2] = product_id.bytes()

	tx.execute('MERGE INTO category_product t
			USING (${get_merge_source(src)}) s
			ON t.product_id = s.product_id AND t.category_id = s.category_id
			WHEN NOT MATCHED THEN
				INSERT (product_id, category_id)
				VALUES (s.product_id, s.category_id)
			WHEN NOT MATCHED BY SOURCE AND t.product_id = ? THEN 
				DELETE',
		...params)!
}
