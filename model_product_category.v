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

fn model_product_category_get(mut tx firebird.Transaction, ph ProductCategoryRetrieveParamsHygienised) ![]ProductCategory {
	if ph.ids.is_set {
		// TODO where id in ()
	}

	if ph.handles.is_set {
		// TODO where handle like
	}

	if ph.is_active.is_set {
		// TODO WHERE is_active = ?
	}

	if ph.is_internal.is_set {
		// TODO WHERE is_internal = ?
	}

	if ph.with_deleted.is_set {
		// TODO WHERE deleted_at IS NULL or IS NOT NULL
	}

	if ph.parent_category_ids.is_set {
		// TODO with recursive
	}

	// TODO offset/fetch/order
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
