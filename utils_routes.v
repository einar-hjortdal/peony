module peony

import net.http

pub const order_direction_asc = 'ASC'
pub const order_direction_desc = 'DESC'
pub const order_direction_default = order_direction_asc

pub const max_length_first_name = 63
pub const max_length_last_name = 63
pub const max_length_alt = 191
pub const max_length_product_title = 63
pub const max_length_product_subtitle = 191
pub const max_length_option_title = 63
pub const max_length_option_value_name = 63
pub const max_length_variant_title = 63
pub const max_length_seo_title = 63
pub const max_length_seo_description = 191
pub const max_length_category_name = 63
pub const max_length_category_description = 191
pub const max_length_region_name = 63

pub const default_thumbnail = 0

fn email_is_valid(e string) ! {
	if e.len > 254 {
		return error('email too long')
	}

	// a@b.cd
	if e.len < 6 {
		return error('email too short')
	}

	// TODO contains @
	// TODO illegal characters
}

fn option_id_string_to_id_bin(option_id_string ?string) ![]u8 {
	if id_string := option_id_string {
		return id_string_to_bin(id_string)!
	}
	return []u8{}
}

fn option_array_id_string_to_array_id_bin(option_array_id_string ?[]string) ![][]u8 {
	if array_id_string := option_array_id_string {
		mut array_id_bin := [][]u8{len: array_id_string.len}
		for i := 0; i < array_id_string.len; i++ {
			array_id_bin[i] = id_string_to_bin(array_id_string[i])!
		}
		return array_id_bin
	}
	return [][]u8{}
}

fn zero_id_string_to_id_bin(zero_id_string ZeroString) ![]u8 {
	if zero_id_string.is_set {
		return id_string_to_bin(zero_id_string.v)!
	}
	return []u8{}
}

fn zero_array_id_string_to_array_id_bin(zero_array_id_string ZeroArrayString) ![][]u8 {
	if zero_array_id_string.is_set {
		mut array_id_bin := [][]u8{len: zero_array_id_string.v.len}
		for i := 0; i < zero_array_id_string.v.len; i++ {
			array_id_bin[i] = id_string_to_bin(zero_array_id_string.v[i])!
		}
		return array_id_bin
	}
	return [][]u8{}
}

fn parse_order_direction(s string) !string {
	normalized := s.to_upper()
	if normalized == order_direction_asc {
		return order_direction_asc
	}

	if normalized == order_desc {
		return order_direction_desc
	}

	return error(error_order_direction_invalid)
}

fn get_order_direction(zs ZeroString) !string {
	if zs.is_set {
		return parse_order_direction(zs.v)
	}
	return ''
}

fn get_header_content_type(mut ctx Context) !string {
	return ctx.get_header(http.CommonHeader.content_type)
}

fn verify_money_amounts(money_amounts []VariantMoneyAmountRequestHygienised, existing_regions []Region) ! {
	mut region_id_map := map[string]bool{}
	for i := 0; i < existing_regions.len; i++ {
		region_id := existing_regions[i].id
		region_id_map[region_id] = true
	}

	mut original_prices_count := 0
	mut base_prices_count := 0
	mut region_map_original_prices := map[string]bool{}
	mut region_map_base_prices := map[string]bool{}
	for i := 0; i < money_amounts.len; i++ {
		money_amount := money_amounts[i]
		region_id := money_amount.region_id
		if region_id !in region_id_map {
			return new_internal_error(error_id_invalid, 'There exists no region with id ${region_id}')
		}

		if is_original := money_amount.is_original {
			if is_original {
				if region_id in region_map_original_prices {
					return new_internal_error('Multiple original_prices per region', 'At most one original_price per region is allowed, received 2 for the same region.')
				}

				original_prices_count++
				region_map_original_prices[region_id] = true
				continue
			}
		}

		if region_id in region_map_base_prices {
			return new_internal_error('Multiple base_prices per region', 'Exactly one base_price per region required, received 2 for the same region.')
		}

		base_prices_count++
		region_map_base_prices[region_id] = true
	}

	if base_prices_count < existing_regions.len {
		return new_internal_error('base_price/region count mismatch', 'Exactly one price per region required, received less prices than the number of existing regions.')
	}
}
