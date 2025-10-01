module peony

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
		return new_internal_error(error_id_invalid, 'ids')
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
	name            ZeroString
	description     ZeroString
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
	currency_code   ZeroString
	title           ZeroString
	with_deleted    ZeroBool
	offset          ZeroI32
	fetch           ZeroI32
	order           ZeroString
}

struct RetrieveProductParamsHygienised {
	ids                   ZeroArrayString
	ids_bin               [][]u8
	handle                ZeroString
	is_giftcard           ZeroBool
	status                ZeroString
	collection_ids        ZeroArrayString
	collection_ids_bin    [][]u8
	type_ids              ZeroArrayString
	type_ids_bin          [][]u8
	tag_ids               ZeroArrayString
	tag_ids_bin           [][]u8
	title                 ZeroString
	description           ZeroString
	category_ids          ZeroArrayString
	category_ids_bin      [][]u8
	price_list_ids        ZeroArrayString
	price_list_ids_bin    [][]u8
	sales_channel_ids     ZeroArrayString
	sales_channel_ids_bin [][]u8
	region_id             ZeroString
	region_id_bin         []u8
	currency_code         ZeroString
	with_deleted          ZeroBool
	offset                ZeroI32
	fetch                 ZeroI32
	order                 ZeroString
	cart_id               ZeroString
	cart_id_bin           []u8
	locale_id             ZeroString
	locale_id_bin         []u8
}

struct ProductCategoryParamsHygienised {
	ids                     ZeroArrayString
	ids_bin                 [][]u8
	handles                 ZeroArrayString
	is_active               ZeroBool
	is_internal             ZeroBool
	product_ids             ZeroArrayString
	product_ids_bin         [][]u8
	parent_category_ids     ZeroArrayString
	parent_category_id_bins [][]u8
	with_deleted            ZeroBool
	offset                  ZeroI32
	fetch                   ZeroI32
	order                   ZeroString
	locale_id               ZeroString
	locale_id_bin           []u8
}

fn hygienise_product_category_params(p ProductCategoryParams) !ProductCategoryParamsHygienised {
	ids_bin := zero_array_id_string_to_array_id_bin(p.ids) or {
		return new_internal_error(error_id_invalid, 'ids')
	}

	parent_category_ids_bin := zero_array_id_string_to_array_id_bin(p.parent_category_ids) or {
		return new_internal_error(error_id_invalid, 'parent_category_ids')
	}

	product_ids_bin := zero_array_id_string_to_array_id_bin(p.product_ids) or {
		return new_internal_error(error_id_invalid, 'product_ids')
	}

	return ProductCategoryParamsHygienised{
		ids:                     p.ids
		ids_bin:                 ids_bin
		handles:                 p.handles
		is_active:               p.is_active
		is_internal:             p.is_internal
		parent_category_ids:     p.parent_category_ids
		parent_category_id_bins: parent_category_ids_bin
		product_ids:             p.product_ids
		product_ids_bin:         product_ids_bin
		with_deleted:            p.with_deleted
		offset:                  p.offset
		fetch:                   p.fetch
		order:                   p.order
	}
}
