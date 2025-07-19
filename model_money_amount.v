module main

import einar_hjortdal.firebird

struct MoneyAmount {
	id                string
	id_bin            []u8
	currency_code     string
	amount            i32
	min_quantity      firebird.NullI32
	max_quantity      firebird.NullI32
	price_list_id_bin firebird.NullArrayU8
	region_id_bin     firebird.NullArrayU8
	variant_id_bin    firebird.NullArrayU8
}

fn parse_money_amount(v []firebird.Value) !MoneyAmount {
	id_bin, _ := v[0].get_array_u8()!
	currency_code, _ := v[1].get_string()!
	amount, _ := v[2].get_i32()!
	min_quantity := v[3].get_null_i32()!
	max_quantity := v[4].get_null_i32()!
	price_list_id_bin := v[5].get_null_array_u8()!
	region_id_bin := v[6].get_null_array_u8()!
	variant_id_bin := v[7].get_null_array_u8()!

	id := id_bin_to_string(id_bin)!

	return MoneyAmount{
		id:                id
		id_bin:            id_bin
		currency_code:     currency_code
		amount:            amount
		min_quantity:      min_quantity
		max_quantity:      max_quantity
		price_list_id_bin: price_list_id_bin
		region_id_bin:     region_id_bin
		variant_id_bin:    variant_id_bin
	}
}
