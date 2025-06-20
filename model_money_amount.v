module main

import einar_hjortdal.firebird

// TODO return price list object?
struct MoneyAmount {
	id                string
	id_bin            []u8
	created_at        firebird.DateTime
	updated_at        firebird.DateTime
	deleted_at        firebird.DateTime
	currency_code     string
	amount            i32
	min_quantity      i32
	max_quantity      i32
	price_list_id     string
	price_list_id_bin []u8
	region_id         string
	region_id_bin     []u8
	variant_id        string
	variant_id_bin    []u8
}

fn parse_money_amount(v []firebird.Value) !MoneyAmount {
	id_bin, _ := v[0].get_array_u8()!
	created_at, _ := v[1].get_date_time()!
	updated_at, _ := v[2].get_date_time()!
	deleted_at, _ := v[3].get_date_time()!
	currency_code, _ := v[4].get_string()!
	amount, _ := v[5].get_i32()!
	min_quantity, _ := v[6].get_i32()!
	max_quantity, _ := v[7].get_i32()!

	price_list_id_bin, price_list_id_is_null := v[8].get_array_u8()!
	region_id_bin, region_id_is_null := v[9].get_array_u8()!
	variant_id_bin, variant_id_is_null := v[10].get_array_u8()!

	id := id_bin_to_string(id_bin)!
	mut price_list_id := ''
	mut region_id := ''
	mut variant_id := ''

	if !price_list_id_is_null {
		price_list_id = id_bin_to_string(price_list_id_bin)!
	}

	if !region_id_is_null {
		region_id = id_bin_to_string(region_id_bin)!
	}

	if !variant_id_is_null {
		variant_id = id_bin_to_string(variant_id_bin)!
	}

	return MoneyAmount{
		id:                id
		id_bin:            id_bin
		created_at:        created_at
		updated_at:        updated_at
		deleted_at:        deleted_at
		currency_code:     currency_code
		amount:            amount
		min_quantity:      min_quantity
		max_quantity:      max_quantity
		price_list_id:     price_list_id
		price_list_id_bin: price_list_id_bin
		region_id:         region_id
		region_id_bin:     region_id_bin
		variant_id:        variant_id
		variant_id_bin:    variant_id_bin
	}
}

struct UpdateMoneyAmountData {
	id            ?string
	currency_code string
	amount        i32
	min_quantity  ?i32
	max_quantity  ?i32
	price_list_id ?string
	region_id     ?string
	variant_id    ?string
}
