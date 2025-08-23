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

// TODO represent children without recursion
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

fn model_product_category_product_update(mut tx firebird.Transaction, product_id_bin []u8, category_ids_bin [][]u8) ! {
	mut s := ''
	mut pa := []firebird.Value{}
	for i := 0; i < category_ids_bin.len; i++ {
		s = appendln(s, 'SELECT ? AS product_id, ? AS product_category_id FROM RDB\$DATABASE')
		pa = arrays.concat(pa, product_id_bin, category_ids_bin[i])
		if i != category_ids_bin.len - 1 {
			s = appendln(s, 'UNION ALL')
		}
	}

	query := 'MERGE INTO product_category_product t
			USING (${s}) s (product_id, product_category_id)
			ON (t.product_id = s.product_id AND t.product_category_id = s.product_category_id)
			WHEN NOT MATCHED THEN
				INSERT (product_id, product_category_id)
				VALUES (s.product_id, s.product_category_id)
			WHEN NOT MATCHED BY SOURCE AND t.product_id = ? THEN DELETE'
	pa = arrays.concat(pa, product_id_bin)

	tx.execute(query, ...pa)!
}
