module main

import arrays
import einar_hjortdal.firebird

fn (mut app App) do_update_product_categories(mut tx firebird.Transaction, product_id_bin []u8, category_ids_bin [][]u8) ! {
	mut s := ''
	mut pa := []firebird.Value{}
	for i := 0; i < category_ids_bin.len; i++ {
		s = appendln(s, 'SELECT ? AS product_id, ? AS product_category_id FROM RDB\$DATABASE')
		pa = arrays.concat(pa, product_id_bin, category_ids_bin[i])
		if i != category_ids_bin.len - 1 {
			s = appendln(s, 'UNION ALL')
		}
	}

	query := 'MERGE INTO product_category_product T USING (${s}) S
			ON (T.product_id = S.product_id AND T.product_category_id = S.product_category_id)
			WHEN NOT MATCHED THEN
				INSERT (product_id, product_category_id)
				VALUES (s.product_id, s.product_category_id)
			WHEN NOT MATCHED BY SOURCE AND t.product_id = ? THEN DELETE'
	pa = arrays.concat(pa, product_id_bin)

	tx.execute(query, ...pa)!
}
