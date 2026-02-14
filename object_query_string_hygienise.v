module peony

fn hygienise_user_list_request_query(m map[string]string) !UserListParams {
	p := extract_user_list_request_query(m)

	ids_bin := zero_array_id_string_to_array_id_bin(p.ids) or {
		return new_error_internal(error_id_invalid, 'ids')
	}

	include_deleted := p.with_deleted.is_set && p.with_deleted.v

	order_direction := get_order_direction(p.order) or {
		return new_error_internal(error_order_direction_invalid, details_order_direction_invalid)
	}

	return UserListParams{
		filter_by_id:        p.ids.is_set
		ids_bin:             ids_bin
		filter_by_email:     p.email.is_set
		email:               p.email.v
		filter_by_handle:    p.handle.is_set
		handle:              p.handle.v
		include_deleted:     include_deleted
		use_offset:          p.offset.is_set
		offset:              p.offset.v
		fetch:               hygienise_fetch_amount(p.fetch)!
		use_order_direction: p.order.is_set
		order_direction:     order_direction
	}
}

fn hygienise_region_list_request_query(p RegionListRequestQuery) !RegionRetriveParams {
	ids_bin := zero_array_id_string_to_array_id_bin(p.ids) or {
		return new_error_bad_request(error_id_invalid, 'ids')
	}

	include_deleted := p.with_deleted.is_set && p.with_deleted.v

	order_direction := get_order_direction(p.order) or {
		return new_error_bad_request(error_order_direction_invalid, details_order_direction_invalid)
	}

	return RegionRetriveParams{
		filter_by_id:        p.ids.is_set
		ids_bin:             ids_bin
		filter_by_name:      p.name.is_set
		include_deleted:     include_deleted
		use_offset:          p.offset.is_set
		offset:              p.offset.v
		fetch:               hygienise_fetch_amount(p.fetch)!
		use_order_direction: p.order.is_set
		order_direction:     order_direction
	}
}

// TODO return error if invalid sorting order
fn hygienise_category_list_request_query(p ProductCategoryListRequestQuery) !CategoryRetrieveParams {
	ids_bin := zero_array_id_string_to_array_id_bin(p.ids) or {
		return new_error_bad_request(error_id_invalid, 'ids')
	}

	parent_category_ids_bin := zero_array_id_string_to_array_id_bin(p.parent_category_ids) or {
		return new_error_bad_request(error_id_invalid, 'parent_category_ids')
	}

	product_ids_bin := zero_array_id_string_to_array_id_bin(p.product_ids) or {
		return new_error_bad_request(error_id_invalid, 'product_ids')
	}

	include_deleted := p.with_deleted.is_set && p.with_deleted.v

	locale_id_bin := zero_id_string_to_id_bin(p.locale_id) or {
		return new_error_bad_request(error_id_invalid, 'locale_id')
	}

	order_direction := get_order_direction(p.order) or {
		return new_error_bad_request(error_order_direction_invalid, details_order_direction_invalid)
	}

	return CategoryRetrieveParams{
		filter_by_id:                  p.ids.is_set
		ids_bin:                       ids_bin
		filter_by_handle:              p.handles.is_set
		handles:                       p.handles.v
		filter_by_is_active:           p.is_active.is_set
		is_active:                     p.is_active.v
		filter_by_is_internal:         p.is_internal.is_set
		is_internal:                   p.is_internal.v
		filter_by_product_ids:         p.product_ids.is_set
		product_ids_bin:               product_ids_bin
		filter_by_parent_category_ids: p.parent_category_ids.is_set
		parent_category_ids_bin:       parent_category_ids_bin
		include_deleted:               include_deleted
		locale_id_bin:                 locale_id_bin
		use_offset:                    p.offset.is_set
		offset:                        p.offset.v
		fetch:                         hygienise_fetch_amount(p.fetch)!
		use_order_direction:           p.order.is_set
		order_direction:               order_direction
	}
}

fn hygienise_category_get_request_query(p ProductCategoryGetRequestQuery, category_id_bin []u8) !CategoryRetrieveParams {
	locale_id_bin := zero_id_string_to_id_bin(p.locale_id) or {
		return new_error_bad_request(error_id_invalid, 'locale_id')
	}

	return CategoryRetrieveParams{
		filter_by_id:  true
		ids_bin:       [category_id_bin]
		locale_id_bin: locale_id_bin
	}
}

struct LocaleRetrieveParamsHygienised {
	ids     ZeroArrayString
	ids_bin [][]u8
	offset  ZeroI32
	fetch   ZeroI32
	order   ZeroString
}

fn hygienise_retrieve_locale_params(m map[string]string) !LocaleRetrieveParamsHygienised {
	ids := zero_array_string(m, 'ids')
	ids_bin := zero_array_id_string_to_array_id_bin(ids) or {
		return new_error_internal(error_id_invalid, 'ids')
	}

	return LocaleRetrieveParamsHygienised{
		ids:     ids
		ids_bin: ids_bin
		offset:  zero_i32(m, 'offset')
		fetch:   zero_i32(m, 'fetch')
		order:   zero_string(m, 'order')
	}
}

struct ListSalesChannelsParamsHygienised {
	ids             ZeroArrayString
	ids_bin         [][]u8
	product_ids     ZeroArrayString
	product_ids_bin [][]u8
	offset          ZeroI32
	fetch           ZeroI32
	order           ZeroString
}

struct RetrieveProductVariantParamsHygienised {
	ids             ZeroArrayString
	ids_bin         [][]u8
	product_ids     ZeroArrayString
	product_ids_bin [][]u8
	allow_backorder ZeroBool
	region_id       ZeroString
	region_id_bin   []u8
	with_deleted    ZeroBool
	offset          ZeroI32
	fetch           ZeroI32
	order           ZeroString
}
