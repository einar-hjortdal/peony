module peony

import einar_hjortdal.firebird

struct Country {
	code          string
	region_id_bin firebird.NullArrayU8
}

fn model_country_list(mut tx firebird.Transaction) !([]Country, i64) {
	data := tx.execute('SELECT code, region_id, COUNT(*) OVER() FROM country')!

	mut countries := []Country{len: data.rows.len}
	for i := 0; i < data.rows.len; i++ {
		v := data.rows[i].values
		code, _ := v[0].get_string()!
		region_id_bin := v[1].get_null_array_u8()!
		country := Country{
			code:          code
			region_id_bin: region_id_bin
		}
		countries[i] = country
	}

	count, _ := data.rows[0].values[2].get_i64()!

	return countries, count
}
