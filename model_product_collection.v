module peony

import arrays
import einar_hjortdal.firebird

struct CollectionTranslation {
	product_collection_id     string
	product_collection_id_bin []u8 @[json: '-']
	locale_id                 string
	locale_id_bin             []u8
	title                     string
}

fn parse_collection_translation(v []firebird.Value) !CollectionTranslation {
	product_collection_id_bin, _ := v[0].get_array_u8()!
	locale_id_bin, _ := v[1].get_array_u8()!
	title, _ := v[2].get_string()!

	product_collection_id := id_bin_to_string(product_collection_id_bin)!
	locale_id := id_bin_to_string(locale_id_bin)!

	return CollectionTranslation{
		product_collection_id:     product_collection_id
		product_collection_id_bin: product_collection_id_bin
		locale_id:                 locale_id
		locale_id_bin:             locale_id_bin
		title:                     title
	}
}

struct Collection {
	id         string
	id_bin     []u8 @[json: '-']
	created_at firebird.DateTime
	updated_at firebird.DateTime
	deleted_at firebird.DateTime @[omitempty]
	handle     string
	metadata   firebird.NullString
mut:
	translations []CollectionTranslation
}

fn parse_collection(v []firebird.Value) !Collection {
	id_bin, _ := v[0].get_array_u8()!
	created_at, _ := v[1].get_date_time()!
	updated_at, _ := v[2].get_date_time()!
	deleted_at, _ := v[3].get_date_time()!
	handle, _ := v[3].get_string()!

	id := id_bin_to_string(id_bin)!

	return Collection{
		id:         id
		id_bin:     id_bin
		created_at: created_at
		updated_at: updated_at
		deleted_at: deleted_at
		handle:     handle
		metadata:   v[4].get_null_string()!
	}
}

struct RetrieveCollectionsParams {
	handle ZeroString
	title  ZeroString
	offset ZeroI32
	fetch  ZeroI32
	order  ZeroString
}

fn extract_retrieve_collections_params(m map[string]string) RetrieveCollectionsParams {
	return RetrieveCollectionsParams{
		handle: zero_string(m, 'handle')
		title:  zero_string(m, 'title')
		offset: zero_i32(m, 'offset')
		fetch:  zero_i32(m, 'fetch')
		order:  zero_string(m, 'order')
	}
}

fn do_retrieve_collections(mut tx firebird.Transaction, p RetrieveCollectionsParams) ![]Collection {
	mut query := 'SELECT id FROM product_collection pc
		LEFT JOIN product_collection_translations pct
		ON pc.id = pct.product_collection_id'
	mut params := []firebird.Value{}

	if p.handle.is_set {
		query = appendln(query, 'WHERE pc.handle = ?')
		params = arrays.concat(params, p.handle.v)
	}

	if p.title.is_set {
		query = appendln(query, "WHERE pct.title LIKE '%' || ? || '%'")
		params = arrays.concat(params, p.title.v)
	}

	order := get_sorting_order(p.order)
	query = appendln(query, 'ORDER BY pc.created_at ${order}')

	if p.offset.is_set {
		query = appendln(query, 'OFFSET ? ROWS')
		params = arrays.concat(params, p.offset.v)
	}

	fetch := get_fetch_amount(p.fetch)
	query = appendln(query, 'FETCH NEXT ? ROWS ONLY')
	params = arrays.concat(params, fetch)

	mut data := tx.execute(query, ...params)!
	mut rows := data.rows()

	mut ids_bin := [][]u8{}
	for i := 0; i < rows.len; i++ {
		id_bin, _ := rows[i].values()[0].get_array_u8()!
		ids_bin = arrays.concat(ids_bin, id_bin)
	}

	data = tx.execute('SELECT id, created_at, updated_at, deleted_at, handle, metadata
		FROM product_collection WHERE id IN ${get_n_placeholders(i32(ids_bin.len))}',
		...ids_bin)!

	rows = data.rows()

	mut collection_map := map[string]Collection{}
	mut ids := []string{len: rows.len}
	for i := 0; i < rows.len; i++ {
		collection := parse_collection(rows[i].values())!
		collection_map[collection.id] = collection
		ids[i] = collection.id
	}

	data = tx.execute('SELECT product_collection_id, locale_id, title FROM product_collection_translations
		WHERE product_collection_id IN ${get_n_placeholders(i32(ids_bin.len))}',
		...ids_bin)!

	rows = data.rows()

	for i := 0; i < rows.len; i++ {
		translation := parse_collection_translation(rows[i].values())!
		collection_map[translation.product_collection_id].translations = arrays.concat(collection_map[translation.product_collection_id].translations,
			translation)
	}

	mut collections := []Collection{len: ids.len}
	for i := 0; i < ids.len; i++ {
		collections[i] = collection_map[ids[i]]
	}

	return collections
}

fn (mut app App) retrieve_collections(p RetrieveCollectionsParams) ![]Collection {
	mut tx := app.start_transaction()!
	collections := do_retrieve_collections(mut tx, p) or {
		tx.rollback()!
		return err
	}
	tx.rollback()!
	return collections
}

struct UpdateCollectionTranslationData {
	locale_id string
	title     ?string
}

struct CollectionData {
	handle       ?string
	translations ?[]UpdateCollectionTranslationData
}

fn (mut app App) do_create_collection(mut tx firebird.Transaction, p CollectionData) ! {
	_, id_bin := app.new_id()
	mut c := ['id']
	mut params := [firebird.Value(id_bin)]

	if handle := p.handle {
		c = arrays.concat(c, handle)
		params = arrays.concat(params, handle)
	}

	tx.execute('INSERT INTO product_collection (${get_columns(c)}) VALUES (${get_n_placeholders(i32(c.len))})',
		...params)!

	if translations := p.translations {
		mut stmt := tx.prepare('INSERT INTO product_collection_translations (product_collection_id,
			locale_id, title) VALUES (?, ?, ?)')!

		for i := 0; i < translations.len; i++ {
			locale_id_bin := id_string_to_bin(translations[i].locale_id)!
			params = [firebird.Value(id_bin), locale_id_bin]
			if title := translations[i] {
				params = arrays.concat(params, title)
				stmt.execute(...params)!
			}
		}
	}
}

fn (mut app App) create_collection(p CollectionData) ! {
	mut tx := app.start_transaction()!
	app.do_create_collection(mut tx, p) or {
		tx.rollback()!
		return err
	}
	tx.commit()!
}
